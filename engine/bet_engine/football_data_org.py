"""Accès à l'API football-data.org (offre gratuite : 10 requêtes par minute)."""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

from .poisson import Result

BASE_URL = "https://api.football-data.org/v4"
PAUSE_SECONDS = 7.0  # 10 requêtes/minute au maximum


def _parse_date(text: str) -> datetime:
    return datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone(timezone.utc)


def parse_matches(payload: dict) -> tuple[list[Result], list[dict]]:
    """Sépare les matchs terminés (historique) et les matchs à venir."""
    results: list[Result] = []
    fixtures: list[dict] = []
    for m in payload.get("matches", []):
        status = m.get("status")
        score = m.get("score") or {}
        full = score.get("fullTime") or {}
        half = score.get("halfTime") or {}
        home = (m.get("homeTeam") or {}).get("name")
        away = (m.get("awayTeam") or {}).get("name")
        if not home or not away or not m.get("utcDate"):
            continue
        when = _parse_date(m["utcDate"])
        if status == "FINISHED" and full.get("home") is not None and full.get("away") is not None:
            results.append(
                Result(
                    home=home,
                    away=away,
                    home_goals=int(full["home"]),
                    away_goals=int(full["away"]),
                    when=when,
                    ht_home=half.get("home"),
                    ht_away=half.get("away"),
                )
            )
        elif status in ("SCHEDULED", "TIMED"):
            fixtures.append({"id": m.get("id"), "home": home, "away": away, "when": when})
    return results, fixtures


def fetch_competition(token: str, code: str, season: int | None) -> dict | None:
    """Renvoie la réponse JSON, ou None si l'accès est refusé (offre gratuite)."""
    url = f"{BASE_URL}/competitions/{code}/matches"
    if season is not None:
        url += f"?season={season}"
    request = urllib.request.Request(url, headers={"X-Auth-Token": token})
    for attempt in range(2):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt == 0:
                time.sleep(65)  # limite par minute atteinte : on attend
                continue
            print(f"[{code} {season}] HTTP {error.code} : ignoré")
            return None
        except (urllib.error.URLError, TimeoutError) as error:
            print(f"[{code} {season}] réseau : {error}")
            return None
    return None
