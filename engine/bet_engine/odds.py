"""Cotes (API-Sports) : rapprochement avec nos matchs et conversion en marchés."""
from __future__ import annotations

import difflib
import re
import unicodedata
from datetime import datetime, timezone

STOP_WORDS = {
    "fc", "cf", "ac", "sc", "afc", "as", "ssc", "cd", "ud", "rc", "rcd", "us",
    "ca", "club", "de", "calcio", "sv", "fk", "sk", "ok", "the",
}

# Noms usuels différents d'une source à l'autre (forme normalisée -> forme commune).
ALIASES = {
    "wolves": "wolverhampton wanderers",
    "spurs": "tottenham hotspur",
    "tottenham": "tottenham hotspur",
    "man city": "manchester city",
    "man united": "manchester united",
    "man utd": "manchester united",
    "inter": "internazionale",
    "inter milan": "internazionale",
    "psg": "paris saint germain",
    "paris sg": "paris saint germain",
    "athletic": "athletic bilbao",
    "athletic club": "athletic bilbao",
    "bayern munich": "bayern munchen",
    "borussia monchengladbach": "monchengladbach",
    "borussia m gladbach": "monchengladbach",
    "bayer leverkusen": "leverkusen",
    "bayer 04 leverkusen": "leverkusen",
    "sporting cp": "sporting lisbon",
    "sporting clube de portugal": "sporting lisbon",
    "sporting": "sporting lisbon",
    "newcastle": "newcastle united",
    "nottingham": "nottingham forest",
    "west ham": "west ham united",
    "brighton": "brighton hove albion",
}

PREFERRED_BOOKMAKERS = ["pinnacle", "bet365", "1xbet", "betway", "unibet", "marathonbet"]


def normalize_name(name: str) -> str:
    text = unicodedata.normalize("NFKD", name or "").encode("ascii", "ignore").decode().lower()
    text = re.sub(r"[^a-z0-9 ]+", " ", text.replace("&", " and "))
    tokens = [
        t for t in text.split()
        if t not in STOP_WORDS and not (t.isdigit() and len(t) <= 2)
    ]
    joined = " ".join(tokens)
    return ALIASES.get(joined, joined)


def name_score(a: str, b: str) -> float:
    na, nb = normalize_name(a), normalize_name(b)
    if not na or not nb:
        return 0.0
    if na == nb:
        return 1.0
    ta, tb = set(na.split()), set(nb.split())
    if ta <= tb or tb <= ta:
        return 0.9
    return difflib.SequenceMatcher(None, na, nb).ratio()


def parse_iso(text: str) -> datetime:
    return datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone(timezone.utc)


def parse_fixtures(payload: dict) -> list[dict]:
    out = []
    for item in payload.get("response") or []:
        try:
            out.append(
                {
                    "id": item["fixture"]["id"],
                    "when": parse_iso(item["fixture"]["date"]),
                    "league_id": item["league"]["id"],
                    "home": item["teams"]["home"]["name"],
                    "away": item["teams"]["away"]["name"],
                }
            )
        except (KeyError, TypeError, ValueError):
            continue
    return out


def match_fixture(
    home: str, away: str, when: datetime, league_id: int,
    candidates: list[dict], max_hours: float = 3.0,
) -> dict | None:
    best, best_score = None, 0.0
    for c in candidates:
        if c["league_id"] != league_id:
            continue
        if abs((c["when"] - when).total_seconds()) > max_hours * 3600:
            continue
        h, a = name_score(home, c["home"]), name_score(away, c["away"])
        if min(h, a) < 0.5:
            continue
        if h + a > best_score:
            best, best_score = c, h + a
    return best if best_score >= 1.3 else None


def _odd(value) -> float | None:
    try:
        number = float(str(value).strip())
    except ValueError:
        return None
    return number if number > 1.0 else None


_SIDE = {"home": 0, "draw": 1, "away": 2}


def extract_markets(bets: list[dict]) -> tuple[dict[str, float], dict[str, float], set[str]]:
    """Cotes par marché (clés du moteur), cotes mi-temps/fin, noms de paris vus."""
    markets: dict[str, float] = {}
    htft: dict[str, float] = {}
    seen: set[str] = set()
    for bet in bets or []:
        raw_name = str(bet.get("name", "")).strip()
        name = raw_name.lower()
        seen.add(raw_name)
        for v in bet.get("values") or []:
            label = str(v.get("value", "")).strip().lower()
            odd = _odd(v.get("odd"))
            if odd is None:
                continue
            if name == "match winner" and label in _SIDE:
                markets[label] = odd
            elif name == "goals over/under":
                m = re.fullmatch(r"(over|under) (\d+(?:\.\d+)?)", label)
                if m and m.group(2) in ("1.5", "2.5", "3.5"):
                    markets[f"{m.group(1)}_{m.group(2).replace('.', '_')}"] = odd
            elif name in ("both teams score", "both teams to score") and label in ("yes", "no"):
                markets[f"btts_{label}"] = odd
            elif name == "double chance":
                key = {"home/draw": "dc_1x", "draw/away": "dc_x2", "home/away": "dc_12"}.get(label)
                if key:
                    markets[key] = odd
            elif name in ("ht/ft double", "halftime/fulltime double", "ht/ft"):
                parts = label.split("/")
                if len(parts) == 2 and parts[0] in _SIDE and parts[1] in _SIDE:
                    htft[f"{_SIDE[parts[0]]}-{_SIDE[parts[1]]}"] = odd
    return markets, htft, seen


def pick_bookmaker(bookmakers: list[dict]) -> dict | None:
    """Choisit le bookmaker de référence : préférence connue, sinon le plus complet."""
    parsed = []
    for b in bookmakers or []:
        markets, htft, _ = extract_markets(b.get("bets") or [])
        parsed.append((b, markets, htft))
    parsed = [p for p in parsed if p[1]]
    if not parsed:
        return None
    for wanted in PREFERRED_BOOKMAKERS:
        for b, markets, htft in parsed:
            if wanted in str(b.get("name", "")).lower() and {"home", "draw", "away"} <= set(markets):
                return {"bookmaker": b.get("name"), "markets": markets, "htft": htft}
    b, markets, htft = max(parsed, key=lambda p: len(p[1]) + len(p[2]))
    return {"bookmaker": b.get("name"), "markets": markets, "htft": htft}


def parse_odds(payload: dict) -> tuple[dict[int, dict], set[str], set[str]]:
    """fixture_id -> cotes choisies ; noms de bookmakers et de paris rencontrés."""
    out: dict[int, dict] = {}
    bookmakers_seen: set[str] = set()
    bets_seen: set[str] = set()
    for item in payload.get("response") or []:
        try:
            fixture_id = item["fixture"]["id"]
        except (KeyError, TypeError):
            continue
        books = item.get("bookmakers") or []
        for b in books:
            bookmakers_seen.add(str(b.get("name", "")))
            for bet in b.get("bets") or []:
                bets_seen.add(str(bet.get("name", "")))
        chosen = pick_bookmaker(books)
        if chosen:
            chosen["updated_at"] = item.get("update")
            out[fixture_id] = chosen
    return out, bookmakers_seen, bets_seen


def attach_odds(match: dict, entry: dict | None) -> bool:
    """Ajoute les cotes à un match du document. Renvoie True si des cotes ont été ajoutées."""
    if not entry:
        return False
    markets = entry["markets"]
    match["odds"] = {
        "bookmaker": entry.get("bookmaker"),
        "updated_at": entry.get("updated_at"),
        "markets": markets,
        "htft": entry.get("htft", {}),
    }
    for m in match.get("markets", []):
        m["odds"] = markets.get(m["key"])
    for combo in match.get("htft", {}).get("combos", []):
        combo["odds"] = entry.get("htft", {}).get(f"{combo['ht']}-{combo['ft']}")
    return True
