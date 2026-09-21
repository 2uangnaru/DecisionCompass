"""Mathematical invariants and fixtures; no claim of predictive validation."""
import random
import unittest
from datetime import date

from decision_formula_reference import (
    Evidence, WEIGHTS, NUMBERS, NATAL, TRANSIT, almanac, aspect_vector,
    bazi_basic, branch_pair, combine, duration_average, element_pair,
    hour_branch, hour_stem, numerology, percent, reading, top_two, western, ziwei,
)


class FormulaTests(unittest.TestCase):
    def test_published_personal_day_fixture(self):
        # Numerology.com: birth month/day Oct 12; target Mar 16, 2020 => 9.
        _, numbers = numerology(date(1990, 10, 12), date(2020, 3, 16))
        self.assertEqual(numbers["personal_day"], 9)

    def test_leap_birth(self):
        e, n = numerology(date(2000, 2, 29), date(2026, 2, 28))
        self.assertEqual(e.coverage, 1)
        self.assertTrue(all(1 <= v <= 9 for v in n.values()))

    def test_hour_boundaries(self):
        self.assertEqual([hour_branch(h) for h in (22, 23, 0, 1, 2, 3, 15, 16, 17)], [11, 0, 0, 1, 1, 2, 8, 8, 9])
        for stem in range(10):
            for hour in range(24):
                self.assertTrue(0 <= hour_stem(stem, hour) <= 9)
        self.assertEqual(hour_stem(0, 23), 0)
        self.assertEqual(hour_stem(1, 0), 2)

    def test_no_false_four_way_clash(self):
        self.assertEqual(branch_pair(0, 6), (-.5, .5))
        self.assertEqual(branch_pair(0, 3), (0, 0))
        self.assertEqual(branch_pair(0, 1), (.5, -.4))

    def test_elements(self):
        self.assertEqual(element_pair(4, 0), (.4, -.2))  # Water nourishes Wood.
        self.assertEqual(element_pair(3, 0), (-.4, 0))  # Metal controls Wood.

    def test_bazi_missing_hour(self):
        e = bazi_basic(0, [0, 2, 4, None], (1, 6), (4, 1))
        self.assertAlmostEqual(e.coverage, .8)
        self.assertEqual(bazi_basic(None, [0, 2, 4, 5], (1, 6), (4, 1)).coverage, 0)

    def test_almanac(self):
        e = almanac(True, False, "open")
        self.assertAlmostEqual(e.a, .065)
        self.assertEqual(e.c, .6)
        self.assertEqual(almanac(None, True, "open").coverage, 0)

    def test_ziwei_complete_and_missing_layers(self):
        events = [("lu", 0), ("quan", 4), ("khoa", 6), ("ky", 1)]
        e = ziwei({"daily": events})
        self.assertAlmostEqual(e.a, (.35 + .6 * .2 + .5 * .25) / 2)
        self.assertAlmostEqual(e.coverage, .25)
        self.assertEqual(ziwei({}).coverage, 0)
        with self.assertRaises(ValueError):
            ziwei({"daily": events[:3]})

    def test_angles_wrap_and_orb(self):
        self.assertEqual(aspect_vector(120, 0, "moon"), (.6, -.3))
        self.assertAlmostEqual(aspect_vector(359, 1, "mars")[1], .4 / 3)
        self.assertEqual(aspect_vector(124, 0, "moon"), (0, 0))
        self.assertEqual(aspect_vector(90, 0, "moon"), (-.5, .3))

    def test_western_missing_not_no_aspect(self):
        self.assertEqual(western({}, {}).coverage, 0)
        e = western({"moon": 124}, {"sun": 0})
        self.assertAlmostEqual(e.coverage, .35 * .3)
        self.assertEqual(e.a, 0)

    def test_weight_sums(self):
        self.assertAlmostEqual(sum(WEIGHTS.values()), 1)
        self.assertAlmostEqual(sum(TRANSIT.values()), 1)
        for w in NATAL.values():
            self.assertAlmostEqual(sum(w.values()), 1)

    def test_worked_example(self):
        e = combine({k: Evidence(v, 0, 1) for k, v in {"B": .3, "Z": .2, "T": .4, "W": .1, "N": .5}.items()})
        self.assertAlmostEqual(e.a, .275)
        self.assertEqual(reading(e)["percentages"], {"YES": 61, "NO": 39})

    def test_missing_does_not_inflate(self):
        e = combine({"N": Evidence(1, -1, 1)})
        self.assertAlmostEqual(e.a, .2)
        self.assertEqual(reading(e)["percentages"]["YES"], 58)
        self.assertEqual(combine({"N": Evidence(1, 1, 0)}).a, 0)

    def test_zero_coverage_and_tie(self):
        self.assertEqual(reading(Evidence())["status"], "insufficient_data")
        self.assertEqual(reading(Evidence(0, 0, 1))["status"], "balanced")
        self.assertIsNone(reading(Evidence(.001, 0, 1))["winner"])

    def test_mode_mapping(self):
        e = Evidence(.5, .5, 1)
        self.assertEqual(reading(e, "act_wait")["winner"], "ACT")
        self.assertEqual(reading(e, "keep_let_go")["winner"], "LET GO")
        self.assertEqual(reading(e, "stay_go")["winner"], "GO")

    def test_duration_average_not_max(self):
        e = duration_average([(3600, Evidence(1, 0, 1)), (10800, Evidence(-1, 0, 1))])
        self.assertEqual(e.a, -.5)
        self.assertEqual(reading(e)["winner"], "NO")

    def test_top_two_ties_and_short_remainder(self):
        e = Evidence(.6, 0, 1)
        ranked = top_two([(7200, 10800, e), (3600, 7200, e), (11000, 11200, Evidence(1, 1, 1))])
        self.assertEqual([x["start"] for x in ranked], [3600, 7200])
        self.assertEqual([x["lucky_score"] for x in ranked], [74, 74])
        self.assertEqual(top_two([]), [])
        self.assertEqual(len(top_two([(0, 900, e)])), 1)

    def test_randomized_bounds_and_determinism(self):
        rng = random.Random(20260918)
        for _ in range(10000):
            modules = {name: Evidence(rng.uniform(-1, 1), rng.uniform(-1, 1), rng.random()) for name in WEIGHTS}
            e = combine(modules)
            self.assertEqual(e, combine(modules))
            self.assertTrue(-1 <= e.a <= 1 and -1 <= e.c <= 1)
            for mode in ("yes_no", "act_wait", "stay_go", "keep_let_go"):
                p = reading(e, mode)["percentages"]
                self.assertEqual(sum(p.values()), 100)
                self.assertTrue(all(10 <= x <= 90 for x in p.values()))

    def test_reject_invalid_features(self):
        with self.assertRaises(ValueError):
            Evidence(float("nan"), 0, 1)
        with self.assertRaises(ValueError):
            percent(2)
        with self.assertRaises(ValueError):
            hour_branch(24)
        with self.assertRaises(ValueError):
            combine({"fake": Evidence()})


if __name__ == "__main__":
    unittest.main(verbosity=2)
