"""Génère data/latest.json : matchs à venir + probabilités du modèle.

Utilisation : FOOTBALL_DATA_TOKEN=... python -m bet_engine.pipeline --out ../data/latest.json
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from typing import Callable

from . import football_data_org as fdo
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

SCHEMA_VERSION = 1

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
            for key, label in MARKET_LABELS
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


def build_document(now: datetime, football: dict) -> dict:
    not_ready = {"status": "non_implemente", "matches": []}
    return {
        "schema": SCHEMA_VERSION,
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


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="../data/latest.json")
    parser.add_argument("--days", type=int, default=7)
    args = parser.parse_args(argv)

    token = os.environ.get("FOOTBALL_DATA_TOKEN", "").strip()
    if not token:
        print("FOOTBALL_DATA_TOKEN absent : ajoutez-le dans les secrets du dépôt.")
        return 1
    now = datetime.now(timezone.utc)
    football = build_football(now, lambda code, season: fdo.fetch_competition(token, code, season), args.days)
    document = build_document(now, football)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        json.dump(document, handle, ensure_ascii=False, indent=1)
    print(f"{len(football['matches'])} matchs analysés, {len(football['excluded'])} exclus.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
