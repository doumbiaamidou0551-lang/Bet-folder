"""Génère data/latest.json : matchs à venir + probabilités du modèle.

Utilisation : FOOTBALL_DATA_TOKEN=... python -m bet_engine.pipeline --out ../data/latest.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from typing import Callable

from . import football_data_org as fdo
from . import odds as odds_mod
from .api_sports import ApiSportsClient
from .poisson import (
    MODEL_VERSION,
    Result,
    expected_goals,
    fit_ratings,
    htft_matrix,
    markets,
    round_pcts,
    score_matrix,
    top_scores,
)

SCHEMA_VERSION = 2

# Compétitions de l'offre gratuite de football-data.org.
COMPETITIONS = [
    ("PL", "Premier League"),
    ("PD", "LaLiga"),
    ("SA", "Serie A"),
    ("BL1", "Bundesliga"),
    ("FL1", "Ligue 1"),
    ("CL", "Ligue des champions"),
    ("DED", "Eredivisie"),
    ("PPL", "Liga Portugal"),
]

# Identifiants API-Sports (API-Football) des mêmes compétitions.
API_LEAGUE_IDS = {"PL": 39, "PD": 140, "SA": 135, "BL1": 78, "FL1": 61, "CL": 2, "DED": 88, "PPL": 94}

MARKET_LABELS = [
    ("over_1_5", "Plus de 1,5 buts"),
    ("under_1_5", "Moins de 1,5 buts"),
    ("over_2_5", "Plus de 2,5 buts"),
    ("under_2_5", "Moins de 2,5 buts"),
    ("over_3_5", "Plus de 3,5 buts"),
    ("under_3_5", "Moins de 3,5 buts"),
    ("btts_yes", "Les deux équipes marquent : oui"),
    ("btts_no", "Les deux équipes marquent : non"),
    ("dc_1x", "Double chance 1X"),
    ("dc_x2", "Double chance X2"),
    ("dc_12", "Double chance 12"),
    ("dnb_home", "Remboursé si nul : domicile"),
    ("dnb_away", "Remboursé si nul : extérieur"),
]


def current_season_year(now: datetime) -> int:
    return now.year if now.month >= 7 else now.year - 1


def _form(results: list[Result], team: str, venue: str | None, count: int) -> dict:
    games = [
        r
        for r in results
        if (r.home == team and venue in (None, "home"))
        or (r.away == team and venue in (None, "away"))
    ]
    games.sort(key=lambda r: r.when, reverse=True)
    games = games[:count]
    letters, gf, ga = [], 0, 0
    for r in games:
        mine, theirs = (
            (r.home_goals, r.away_goals) if r.home == team else (r.away_goals, r.home_goals)
        )
        gf += mine
        ga += theirs
        letters.append("V" if mine > theirs else ("N" if mine == theirs else "D"))
    n = len(games)
    return {
        "matches": n,
        "last": "".join(letters),
        "goals_for": round(gf / n, 2) if n else None,
        "goals_against": round(ga / n, 2) if n else None,
    }


def build_match(code: str, name: str, fixture: dict, results: list[Result], ratings) -> dict | None:
    home, away = fixture["home"], fixture["away"]
    if home not in ratings.attack or away not in ratings.attack:
        return None  # équipe sans historique : pas d'analyse (règle de non-publication)
    lam_h, lam_a = expected_goals(ratings, home, away)
    matrix = score_matrix(lam_h, lam_a, ratings.rho)
    mk = markets(matrix)
    p1, px, p2 = round_pcts([mk["home"], mk["draw"], mk["away"]])

    best = top_scores(matrix, 3)
    scores = {
        "suggestions": [
            {"score": s, "pct": round(p * 100)} for s, p in best[:2]
        ],
        "alternative": {"score": best[2][0], "pct": round(best[2][1] * 100)},
    }

    ft = (mk["home"], mk["draw"], mk["away"])
    ht = htft_matrix(lam_h, lam_a, ratings.first_half_share, ft)
    flat = [ht[i][j] for i in range(3) for j in range(3)]
    flat_pct = round_pcts(flat)
    combos = [
        {"ht": i, "ft": j, "pct": flat_pct[i * 3 + j]} for i in range(3) for j in range(3)
    ]
    ht_pcts = round_pcts([sum(ht[i]) for i in range(3)])

    n_home = sum(1 for r in results if fixture["home"] in (r.home, r.away))
    n_away = sum(1 for r in results if fixture["away"] in (r.home, r.away))
    sample = min(n_home, n_away)
    # Pas de confiance « élevée » sans compositions ni cotes : plafond « moyenne ».
    confidence = "faible" if sample < 8 else "moyenne"

    return {
        "id": f"fd-{fixture['id']}",
        "competition": name,
        "competition_code": code,
        "kickoff_utc": fixture["when"].strftime("%Y-%m-%dT%H:%M:%SZ"),
        "home": home,
        "away": away,
        "model": {
            "version": MODEL_VERSION,
            "lambda_home": round(lam_h, 3),
            "lambda_away": round(lam_a, 3),
            "rho": round(ratings.rho, 2),
            "confidence": confidence,
            "sample_matches": {"home": n_home, "away": n_away},
        },
        "probs": {"home": p1, "draw": px, "away": p2},
        "markets": [
            {"key": key, "label": label, "pct": round(mk[key] * 100)}
            for key, label in (
                [("home", f"Victoire {home}"), ("draw", "Match nul"), ("away", f"Victoire {away}")]
                + MARKET_LABELS
            )
        ],
        "scores": scores,
        "htft": {
            "ht": {"home": ht_pcts[0], "draw": ht_pcts[1], "away": ht_pcts[2]},
            "combos": combos,
        },
        "form": {
            "home_team": _form(results, home, None, 5),
            "away_team": _form(results, away, None, 5),
            "home_team_at_home": _form(results, home, "home", 5),
            "away_team_away": _form(results, away, "away", 5),
        },
        "odds": None,  # cotes : source à brancher (étape suivante)
        "lineups": "non_confirmees",
    }


def build_football(
    now: datetime,
    fetch: Callable[[str, int | None], dict | None],
    days_ahead: int = 7,
    pause: Callable[[float], None] = time.sleep,
) -> dict:
    matches: list[dict] = []
    excluded: list[dict] = []
    season = current_season_year(now)
    window_end = now + timedelta(days=days_ahead)
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)

    for code, name in COMPETITIONS:
        history: list[Result] = []
        fixtures: list[dict] = []
        for s in (season, season - 1):
            payload = fetch(code, s)
            pause(fdo.PAUSE_SECONDS)
            if payload is None:
                continue
            res, fix = fdo.parse_matches(payload)
            history.extend(res)
            if s == season:
                fixtures = fix
        upcoming = [f for f in fixtures if start_of_day <= f["when"] <= window_end]
        if not upcoming:
            continue
        try:
            ratings = fit_ratings(history, now)
        except ValueError as error:
            excluded.append({"competition": name, "reason": str(error)})
            continue
        for fixture in upcoming:
            m = build_match(code, name, fixture, history, ratings)
            if m is None:
                excluded.append(
                    {
                        "competition": name,
                        "match": f"{fixture['home']} – {fixture['away']}",
                        "reason": "équipe sans historique",
                    }
                )
            else:
                matches.append(m)
    matches.sort(key=lambda m: m["kickoff_utc"])
    return {"matches": matches, "excluded": excluded}


def enrich_with_odds(matches: list[dict], client, now: datetime, days: int = 2) -> dict:
    """Ajoute les cotes API-Sports aux matchs des prochains jours. Renvoie un rapport."""
    season = current_season_year(now)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    horizon = start + timedelta(days=days)
    targets = [
        m for m in matches
        if start <= odds_mod.parse_iso(m["kickoff_utc"]) < horizon
        and m["competition_code"] in API_LEAGUE_IDS
    ]
    report = {"enabled": True, "targets": len(targets), "matched": 0, "with_odds": 0,
              "unmatched": [], "bookmakers": [], "bet_names": []}
    if not targets:
        report["requests"] = client.calls
        return report

    fixtures: list[dict] = []
    for day in sorted({m["kickoff_utc"][:10] for m in targets}):
        payload = client.get("fixtures", {"date": day})
        if payload:
            fixtures.extend(odds_mod.parse_fixtures(payload))
    report["fixtures_listed"] = len(fixtures)

    pairs: list[tuple[dict, dict]] = []
    for m in targets:
        league_id = API_LEAGUE_IDS[m["competition_code"]]
        found = odds_mod.match_fixture(
            m["home"], m["away"], odds_mod.parse_iso(m["kickoff_utc"]), league_id, fixtures
        )
        if found is None:
            report["unmatched"].append(f"{m['home']} – {m['away']}")
        else:
            pairs.append((m, found))
    report["matched"] = len(pairs)

    odds_by_fixture: dict[int, dict] = {}
    bookmakers_seen: set[str] = set()
    bets_seen: set[str] = set()
    combos = sorted({(f["league_id"], f["when"].strftime("%Y-%m-%d")) for _, f in pairs})
    for league_id, day in combos:
        page, total = 1, 1
        while page <= total and page <= 3:
            payload = client.get("odds", {"league": league_id, "season": season, "date": day, "page": page})
            if not payload:
                break
            found, books, bets = odds_mod.parse_odds(payload)
            odds_by_fixture.update(found)
            bookmakers_seen |= books
            bets_seen |= bets
            total = int((payload.get("paging") or {}).get("total") or 1)
            page += 1

    for m, fixture in pairs:
        if odds_mod.attach_odds(m, odds_by_fixture.get(fixture["id"])):
            report["with_odds"] += 1
    report["bookmakers"] = sorted(bookmakers_seen)[:30]
    report["bet_names"] = sorted(bets_seen)[:60]
    report["requests"] = client.calls
    report["errors"] = client.errors[:10]
    return report


def build_document(now: datetime, football: dict, diagnostics: dict | None = None) -> dict:
    not_ready = {"status": "non_implemente", "matches": []}
    return {
        "schema": SCHEMA_VERSION,
        "diagnostics": diagnostics or {},
        "generated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "data_sources": [
            {"name": "football-data.org", "sport": "football", "retrieved_at": now.strftime("%Y-%m-%dT%H:%M:%SZ")}
        ],
        "sports": {
            "football": {"status": "ok", **football},
            "basketball": not_ready,
            "tennis": not_ready,
            "hockey": not_ready,
        },
    }


def clean_token(raw: str) -> str:
    """Extrait le jeton d'un texte collé (espaces, retours à la ligne, libellé...)."""
    runs = re.findall(r"[A-Za-z0-9]{20,}", raw or "")
    return runs[0] if runs else ""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="../data/latest.json")
    parser.add_argument("--days", type=int, default=7)
    args = parser.parse_args(argv)

    raw_token = os.environ.get("FOOTBALL_DATA_TOKEN", "")
    token = clean_token(raw_token)
    if not token:
        print(
            "FOOTBALL_DATA_TOKEN absent ou invalide : il doit contenir uniquement "
            "des lettres et des chiffres, sans espace ni retour à la ligne."
        )
        return 1
    if token != raw_token:
        print("Le secret contenait des caractères en trop : jeton nettoyé automatiquement.")
    now = datetime.now(timezone.utc)
    football = build_football(now, lambda code, season: fdo.fetch_competition(token, code, season), args.days)
    diagnostics: dict = {}
    api_key = clean_token(os.environ.get("API_SPORTS_KEY", ""))
    if api_key:
        client = ApiSportsClient(api_key)
        try:
            diagnostics["api_sports"] = enrich_with_odds(football["matches"], client, now)
        except Exception as error:  # les cotes sont un plus : on ne bloque jamais les probabilités
            diagnostics["api_sports"] = {"enabled": True, "error": str(error)[:200]}
        print("API-Sports :", json.dumps(diagnostics["api_sports"], ensure_ascii=False)[:600])
    else:
        diagnostics["api_sports"] = {"enabled": False, "reason": "API_SPORTS_KEY absent"}
        print("API_SPORTS_KEY absent : cotes non chargées.")
    document = build_document(now, football, diagnostics)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        json.dump(document, handle, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(football['matches'])} matchs analysés, {len(football['excluded'])} exclus.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
