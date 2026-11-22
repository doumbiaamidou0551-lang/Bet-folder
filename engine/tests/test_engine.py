import math
import random
import unittest
from datetime import datetime, timedelta, timezone

from bet_engine import football_data_org as fdo
from bet_engine import pipeline
from bet_engine.poisson import (
    Result,
    expected_goals,
    fit_ratings,
    htft_matrix,
    markets,
    round_pcts,
    score_matrix,
    top_scores,
)

NOW = datetime(2026, 11, 22, 0, 20, tzinfo=timezone.utc)


def poisson_sample(rng: random.Random, lam: float) -> int:
    limit, k, p = math.exp(-lam), 0, 1.0
    while True:
        p *= rng.random()
        if p <= limit:
            return k
        k += 1


def synthetic_league(seed: int = 7, teams: int = 12):
    """Championnat fictif : forces connues, deux saisons aller-retour."""
    rng = random.Random(seed)
    names = [f"Equipe {i:02d}" for i in range(teams)]
    attack = {n: 0.6 + 1.0 * i / (teams - 1) for i, n in enumerate(names)}
    defence = {n: 1.4 - 0.8 * i / (teams - 1) for i, n in enumerate(names)}
    results, day = [], 0
    for season_offset in (400, 40):
        for h in names:
            for a in names:
                if h == a:
                    continue
                day += 1
                when = NOW - timedelta(days=season_offset - (day % 300) * 0.5)
                lam_h = attack[h] * defence[a] * 1.3
                lam_a = attack[a] * defence[h]
                hg, ag = poisson_sample(rng, lam_h), poisson_sample(rng, lam_a)
                h1 = sum(1 for _ in range(hg) if rng.random() < 0.45)
                a1 = sum(1 for _ in range(ag) if rng.random() < 0.45)
                results.append(Result(h, a, hg, ag, when, h1, a1))
    return names, attack, defence, results


class PoissonTests(unittest.TestCase):
    def test_ratings_recover_team_order(self):
        import statistics

        names, attack, defence, results = synthetic_league()
        r = fit_ratings(results, NOW)
        ranked = sorted(names, key=lambda n: r.attack[n])
        self.assertIn(names[-1], ranked[-3:])  # meilleure attaque parmi les 3 premières
        self.assertIn(names[0], ranked[:3])  # pire attaque parmi les 3 dernières
        self.assertGreater(
            statistics.correlation([r.attack[n] for n in names], [attack[n] for n in names]), 0.8
        )
        self.assertGreater(
            statistics.correlation([r.defence[n] for n in names], [defence[n] for n in names]), 0.8
        )
        self.assertGreater(r.home_adv, 1.1)
        self.assertLess(r.home_adv, 1.5)
        self.assertLessEqual(r.rho, 0.0)

    def test_score_matrix_and_markets_are_coherent(self):
        m = score_matrix(1.7, 1.1, -0.05)
        self.assertAlmostEqual(sum(sum(row) for row in m), 1.0, places=9)
        mk = markets(m)
        self.assertAlmostEqual(mk["home"] + mk["draw"] + mk["away"], 1.0, places=9)
        self.assertAlmostEqual(mk["dc_1x"], mk["home"] + mk["draw"], places=9)
        self.assertAlmostEqual(mk["over_2_5"] + mk["under_2_5"], 1.0, places=9)
        self.assertGreater(mk["over_1_5"], mk["over_2_5"])
        self.assertGreater(mk["over_2_5"], mk["over_3_5"])
        self.assertGreater(mk["home"], mk["away"])

    def test_top_scores_are_distinct_and_sorted(self):
        m = score_matrix(1.4, 1.2, -0.05)
        top = top_scores(m, 3)
        self.assertEqual(len({s for s, _ in top}), 3)
        self.assertGreaterEqual(top[0][1], top[1][1])
        self.assertGreaterEqual(top[1][1], top[2][1])

    def test_htft_margins_match_full_time_probabilities(self):
        m = score_matrix(1.6, 1.0, -0.05)
        mk = markets(m)
        ft = (mk["home"], mk["draw"], mk["away"])
        ht = htft_matrix(1.6, 1.0, 0.45, ft)
        for j in range(3):
            self.assertAlmostEqual(sum(ht[i][j] for i in range(3)), ft[j], places=9)
        self.assertAlmostEqual(sum(sum(row) for row in ht), 1.0, places=9)

    def test_round_pcts_sum_to_100(self):
        for values in ([0.333, 0.333, 0.334], [0.455, 0.275, 0.27], [1, 1, 1]):
            self.assertEqual(sum(round_pcts(values)), 100)

    def test_too_small_sample_is_refused(self):
        with self.assertRaises(ValueError):
            fit_ratings([Result("A", "B", 1, 0, NOW)], NOW)


class ProviderTests(unittest.TestCase):
    def test_parse_matches_splits_history_and_fixtures(self):
        payload = {
            "matches": [
                {"id": 1, "utcDate": "2026-11-01T15:00:00Z", "status": "FINISHED",
                 "homeTeam": {"name": "A"}, "awayTeam": {"name": "B"},
                 "score": {"fullTime": {"home": 2, "away": 1}, "halfTime": {"home": 1, "away": 0}}},
                {"id": 2, "utcDate": "2026-11-23T15:00:00Z", "status": "TIMED",
                 "homeTeam": {"name": "C"}, "awayTeam": {"name": "D"},
                 "score": {"fullTime": {"home": None, "away": None}}},
                {"id": 3, "utcDate": "2026-11-02T15:00:00Z", "status": "POSTPONED",
                 "homeTeam": {"name": "E"}, "awayTeam": {"name": "F"}, "score": {}},
            ]
        }
        results, fixtures = fdo.parse_matches(payload)
        self.assertEqual(len(results), 1)
        self.assertEqual((results[0].home_goals, results[0].ht_home), (2, 1))
        self.assertEqual(len(fixtures), 1)
        self.assertEqual(fixtures[0]["home"], "C")


class PipelineTests(unittest.TestCase):
    def test_document_for_a_fake_competition(self):
        names, _, _, results = synthetic_league(seed=11)

        def fake_fetch(code, season):
            if code != "PL":
                return None
            if season == pipeline.current_season_year(NOW):
                matches = [
                    {"id": 100 + i, "utcDate": (NOW + timedelta(days=1, hours=i)).strftime("%Y-%m-%dT%H:%M:%SZ"),
                     "status": "TIMED", "homeTeam": {"name": names[-1 - i]}, "awayTeam": {"name": names[i]},
                     "score": {"fullTime": {"home": None, "away": None}}}
                    for i in range(3)
                ]
                matches.append({"id": 999, "utcDate": (NOW + timedelta(days=2)).strftime("%Y-%m-%dT%H:%M:%SZ"),
                                "status": "TIMED", "homeTeam": {"name": "Promu FC"}, "awayTeam": {"name": names[0]},
                                "score": {"fullTime": {"home": None, "away": None}}})
                return {"matches": matches}
            return {"matches": [
                {"id": i, "utcDate": r.when.strftime("%Y-%m-%dT%H:%M:%SZ"), "status": "FINISHED",
                 "homeTeam": {"name": r.home}, "awayTeam": {"name": r.away},
                 "score": {"fullTime": {"home": r.home_goals, "away": r.away_goals},
                           "halfTime": {"home": r.ht_home, "away": r.ht_away}}}
                for i, r in enumerate(results)
            ]}

        football = pipeline.build_football(NOW, fake_fetch, pause=lambda s: None)
        doc = pipeline.build_document(NOW, football)
        self.assertEqual(doc["schema"], 1)
        self.assertEqual(doc["sports"]["basketball"]["status"], "non_implemente")
        matches = doc["sports"]["football"]["matches"]
        self.assertEqual(len(matches), 3)
        self.assertEqual(len(doc["sports"]["football"]["excluded"]), 1)  # équipe promue sans historique
        for m in matches:
            p = m["probs"]
            self.assertEqual(p["home"] + p["draw"] + p["away"], 100)
            self.assertEqual(sum(c["pct"] for c in m["htft"]["combos"]), 100)
            self.assertEqual(len(m["htft"]["combos"]), 9)
            self.assertEqual(len(m["scores"]["suggestions"]), 2)
            self.assertNotEqual(m["scores"]["suggestions"][0]["score"], m["scores"]["alternative"]["score"])
            self.assertIn(m["model"]["confidence"], ("faible", "moyenne"))
            self.assertIsNone(m["odds"])
            self.assertTrue(m["kickoff_utc"].endswith("Z"))
        # le favori théorique (équipe forte à domicile) doit ressortir
        self.assertGreater(matches[0]["probs"]["home"], matches[0]["probs"]["away"])


if __name__ == "__main__":
    unittest.main()
