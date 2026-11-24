import unittest
from datetime import datetime, timedelta, timezone

from bet_engine import odds as om
from bet_engine import pipeline
from bet_engine.api_sports import ApiSportsClient

NOW = datetime(2026, 11, 22, 0, 20, tzinfo=timezone.utc)


def bets(home=2.10, draw=3.40, away=3.60):
    return [
        {"id": 1, "name": "Match Winner", "values": [
            {"value": "Home", "odd": str(home)}, {"value": "Draw", "odd": str(draw)}, {"value": "Away", "odd": str(away)}]},
        {"id": 5, "name": "Goals Over/Under", "values": [
            {"value": "Over 2.5", "odd": "1.90"}, {"value": "Under 2.5", "odd": "1.95"},
            {"value": "Over 1.5", "odd": "1.30"}, {"value": "Over 7.5", "odd": "40.00"}]},
        {"id": 6, "name": "Goals Over/Under First Half", "values": [{"value": "Over 0.5", "odd": "1.40"}]},
        {"id": 8, "name": "Both Teams Score", "values": [{"value": "Yes", "odd": "1.80"}, {"value": "No", "odd": "1.95"}]},
        {"id": 12, "name": "Double Chance", "values": [
            {"value": "Home/Draw", "odd": "1.30"}, {"value": "Draw/Away", "odd": "1.75"}, {"value": "Home/Away", "odd": "1.28"}]},
        {"id": 7, "name": "HT/FT Double", "values": [
            {"value": "Home/Home", "odd": "3.60"}, {"value": "Draw/Draw", "odd": "4.60"}, {"value": "Away/Away", "odd": "7.00"}]},
    ]


class NameTests(unittest.TestCase):
    def test_names_from_two_providers_match(self):
        pairs = [
            ("AC Monza", "Monza"), ("ACF Fiorentina", "Fiorentina"),
            ("Paris Saint-Germain FC", "Paris Saint Germain"),
            ("Wolverhampton Wanderers FC", "Wolves"),
            ("Club Atlético de Madrid", "Atletico Madrid"),
            ("Brighton & Hove Albion FC", "Brighton"),
            ("Bayer 04 Leverkusen", "Bayer Leverkusen"),
            ("Manchester City FC", "Manchester City"),
        ]
        for a, b in pairs:
            self.assertGreaterEqual(om.name_score(a, b), 0.85, f"{a} / {b}")

    def test_different_teams_do_not_match(self):
        self.assertLess(om.name_score("Real Madrid CF", "Real Sociedad"), 0.85)
        self.assertLess(om.name_score("Arsenal FC", "Chelsea FC"), 0.5)

    def test_match_fixture_uses_time_and_league(self):
        when = NOW + timedelta(days=1, hours=19)
        cands = [
            {"id": 1, "when": when, "league_id": 135, "home": "Monza", "away": "Fiorentina"},
            {"id": 2, "when": when, "league_id": 135, "home": "Roma", "away": "Lazio"},
            {"id": 3, "when": when + timedelta(days=1), "league_id": 135, "home": "Monza", "away": "Fiorentina"},
            {"id": 4, "when": when, "league_id": 39, "home": "Monza", "away": "Fiorentina"},
        ]
        found = om.match_fixture("AC Monza", "ACF Fiorentina", when, 135, cands)
        self.assertEqual(found["id"], 1)
        self.assertIsNone(om.match_fixture("Inter", "Milan", when, 135, cands))


class ExtractTests(unittest.TestCase):
    def test_markets_are_mapped_to_engine_keys(self):
        markets, htft, seen = om.extract_markets(bets())
        self.assertEqual(markets["home"], 2.10)
        self.assertEqual(markets["over_2_5"], 1.90)
        self.assertEqual(markets["under_2_5"], 1.95)
        self.assertEqual(markets["over_1_5"], 1.30)
        self.assertNotIn("over_7_5", markets)  # ligne non gérée
        self.assertEqual(markets["btts_yes"], 1.80)
        self.assertEqual(markets["dc_1x"], 1.30)
        self.assertEqual(markets["dc_x2"], 1.75)
        self.assertEqual(markets["dc_12"], 1.28)
        self.assertEqual(htft["0-0"], 3.60)
        self.assertEqual(htft["2-2"], 7.00)
        self.assertIn("Goals Over/Under First Half", seen)

    def test_first_half_totals_do_not_pollute_full_time(self):
        markets, _, _ = om.extract_markets(bets())
        self.assertNotIn("over_0_5", markets)

    def test_reference_bookmaker_is_preferred(self):
        books = [
            {"name": "Obscure", "bets": bets(2.5, 3.2, 3.0) + bets()},
            {"name": "Bet365", "bets": bets(2.0, 3.3, 3.7)},
            {"name": "Pinnacle", "bets": bets(2.10, 3.40, 3.60)},
        ]
        chosen = om.pick_bookmaker(books)
        self.assertEqual(chosen["bookmaker"], "Pinnacle")
        self.assertIsNone(om.pick_bookmaker([{"name": "X", "bets": []}]))


class FakeClient:
    def __init__(self, fixtures, odds):
        self.calls = 0
        self.errors = []
        self._fixtures, self._odds = fixtures, odds

    def get(self, endpoint, params):
        self.calls += 1
        return self._fixtures if endpoint == "fixtures" else self._odds


class EnrichTests(unittest.TestCase):
    def test_odds_are_attached_to_matching_matches(self):
        kickoff = NOW + timedelta(days=1, hours=19)
        stamp = kickoff.strftime("%Y-%m-%dT%H:%M:%SZ")
        match = {
            "id": "fd-1", "competition_code": "SA", "home": "AC Monza", "away": "ACF Fiorentina",
            "kickoff_utc": stamp,
            "markets": [{"key": "home", "label": "x", "pct": 45}, {"key": "over_2_5", "label": "y", "pct": 55}],
            "htft": {"combos": [{"ht": 0, "ft": 0, "pct": 26}, {"ht": 1, "ft": 1, "pct": 21}]},
        }
        other = dict(match, id="fd-2", home="Roma", away="Lazio")
        fixtures = {"response": [{
            "fixture": {"id": 777, "date": kickoff.isoformat()}, "league": {"id": 135},
            "teams": {"home": {"name": "Monza"}, "away": {"name": "Fiorentina"}}}]}
        odds = {"paging": {"current": 1, "total": 1}, "response": [{
            "fixture": {"id": 777}, "update": "2026-11-22T10:00:00+00:00",
            "bookmakers": [{"id": 4, "name": "Pinnacle", "bets": bets()}]}]}
        client = FakeClient(fixtures, odds)
        report = pipeline.enrich_with_odds([match, other], client, NOW)
        self.assertEqual(report["matched"], 1)
        self.assertEqual(report["with_odds"], 1)
        self.assertEqual(report["unmatched"], ["Roma – Lazio"])
        self.assertEqual(match["odds"]["bookmaker"], "Pinnacle")
        self.assertEqual(match["markets"][0]["odds"], 2.10)
        self.assertEqual(match["markets"][1]["odds"], 1.90)
        self.assertEqual(match["htft"]["combos"][0]["odds"], 3.60)
        self.assertNotIn("odds", other)
        self.assertIn("Match Winner", report["bet_names"])


class ClientTests(unittest.TestCase):
    def test_safety_limit_stops_requests(self):
        client = ApiSportsClient("k" * 32, pause=0, max_calls=0, sleeper=lambda s: None)
        self.assertIsNone(client.get("status", {}))
        self.assertTrue(client.errors)


if __name__ == "__main__":
    unittest.main()
