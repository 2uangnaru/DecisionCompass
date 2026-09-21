import random
import unittest
from decision_formula_reference import Evidence, reading
from decision_formula_v2 import (
    WEIGHTS, HIDDEN, GODS, MAJOR, AUX, TRIGRAM, WANDERING, LUOSHU_PATH,
    Pillar, Space, Star, annual_center, bazi_expanded, bazi_profile,
    bearing_sector, combine_v2, cosmic, life_gua, lo_shu, mansion,
    period_number, spatial, ten_god, ziwei_expanded,
)


class ExpandedTests(unittest.TestCase):
    def test_ten_gods_jia_and_all_day_masters(self):
        self.assertEqual([ten_god(0, s) for s in range(10)], ["peer", "competitor", "expression", "challenge", "opportunity", "stewardship", "pressure", "responsibility", "reflection", "support"])
        for dm in range(10):
            self.assertEqual({ten_god(dm, s) for s in range(10)}, set(GODS))

    def test_hidden_stems_complete(self):
        self.assertEqual(set(HIDDEN), set(range(12)))
        self.assertEqual(set(HIDDEN[5]), {2, 4, 6})
        self.assertEqual(HIDDEN[0], (9,))

    def test_invalid_pillar(self):
        with self.assertRaises(ValueError):
            Pillar(0, 1)

    def test_profile_missing_hour_and_mass(self):
        p = bazi_profile([Pillar(0, 0), Pillar(2, 2), Pillar(4, 4), None])
        self.assertAlmostEqual(sum(p["element_distribution"]), 1)
        self.assertAlmostEqual(p["coverage"], 3.5 / 4.5)
        self.assertTrue(0 <= p["support_index"] <= 1)

    def test_triple_requires_all_three(self):
        p = bazi_profile([Pillar(0, 0), Pillar(2, 8), Pillar(4, 4), None])
        self.assertEqual(p["complete_three_harmony_sets"], [[8, 0, 4]])
        p = bazi_profile([Pillar(0, 0), Pillar(2, 8), Pillar(4, 6), None])
        self.assertEqual(p["complete_three_harmony_sets"], [])

    def test_reviewed_favorable_map_not_fabricated(self):
        natal = [Pillar(0, 0), Pillar(2, 2), Pillar(4, 4), Pillar(6, 6)]
        e, _ = bazi_expanded(natal, {"daily": Pillar(8, 8)})
        self.assertAlmostEqual(e.coverage, .30 * .85)
        reviewed, _ = bazi_expanded(natal, {"daily": Pillar(8, 8)}, {x: .5 for x in range(5)})
        self.assertAlmostEqual(reviewed.coverage, .30)
        self.assertGreater(reviewed.a * reviewed.coverage, e.a * e.coverage)

    def test_bazi_missing_day(self):
        self.assertEqual(bazi_expanded([None] * 4, {})[0].coverage, 0)

    def test_ziwei_requires_complete_major_catalog(self):
        all_major = [Star(name, i % 12, "miao") for i, name in enumerate(MAJOR)]
        e, _ = ziwei_expanded(all_major, {"life": 0}, {})
        self.assertAlmostEqual(e.coverage, .45)
        e, _ = ziwei_expanded(all_major[:-1], {"life": 0}, {})
        self.assertEqual(e.coverage, 0)

    def test_ziwei_unknown_birth_time(self):
        e, _ = ziwei_expanded([], {}, {}, birth_time_known=False)
        self.assertEqual(e.coverage, 0)

    def test_unknown_major_brightness_not_invented(self):
        e, _ = ziwei_expanded([Star(name, 0) for name in MAJOR], {"life": 0}, {})
        self.assertEqual(e.coverage, 0)

    def test_ziwei_duplicates_rejected(self):
        with self.assertRaises(ValueError):
            ziwei_expanded([Star("ziwei", 0), Star("ziwei", 1)], {"life": 0}, {})

    def test_ziwei_brightness(self):
        stars = [Star(name, 0, "miao") for name in MAJOR]
        faded = [Star(name, 0, "xian") for name in MAJOR]
        a, _ = ziwei_expanded(stars, {"life": 0}, {})
        b, _ = ziwei_expanded(faded, {"life": 0}, {})
        self.assertAlmostEqual(a.a / 2, b.a)

    def test_ziwei_full_feature_layers(self):
        stars = [Star(name, i % 12, "ping") for i, name in enumerate(list(MAJOR) + list(AUX))]
        events = [{"kind": k, "palace": p} for k, p in zip(("lu", "quan", "khoa", "ky"), (0, 4, 6, 3))]
        layers = {k: {"target": 0, "events": events} for k in ("natal", "decade", "yearly", "monthly", "daily", "hourly")}
        e, details = ziwei_expanded(stars, {"life": 0}, layers)
        self.assertAlmostEqual(e.coverage, 1)
        self.assertEqual(details["scored_major"], 14)

    def test_life_gua_examples(self):
        self.assertEqual(life_gua(1974, "female"), 7)
        self.assertEqual(life_gua(1968, "male"), 2)
        self.assertEqual(life_gua(1957, "female"), 8)
        self.assertEqual(life_gua(2000, "male"), 9)
        self.assertEqual(life_gua(2000, "female"), 6)
        self.assertIsNone(life_gua(2000, None))

    def test_mansion_directions(self):
        self.assertEqual(mansion(1, "SE"), "sheng_qi")
        self.assertEqual(mansion(1, "NE"), "wu_gui")
        self.assertEqual(mansion(7, "NE"), "yan_nian")
        self.assertEqual(mansion(8, "NW"), "tian_yi")
        from decision_formula_v2 import SECTORS
        for gua in TRIGRAM:
            self.assertEqual({mansion(gua, s) for s in SECTORS}, set(WANDERING.values()))

    def test_compass_boundary_and_wrap(self):
        self.assertEqual(bearing_sector(359, 2), "N")
        self.assertEqual(bearing_sector(-90, 2), "W")
        self.assertIsNone(bearing_sector(22.5, 0))
        self.assertIsNone(bearing_sector(21, 3))
        self.assertEqual(bearing_sector(135, 2), "SE")

    def test_luoshu_known_base_chart(self):
        self.assertEqual(lo_shu(8), {"C": 8, "NW": 9, "W": 1, "NE": 2, "S": 3, "N": 4, "SW": 5, "E": 6, "SE": 7})
        for center in range(1, 10):
            self.assertEqual(sorted(lo_shu(center, False).values()), list(range(1, 10)))
        self.assertEqual(period_number(2023), 8)
        self.assertEqual(period_number(2024), 9)
        self.assertEqual(annual_center(2026), 1)

    def test_space_missing_and_inactive(self):
        self.assertEqual(spatial(None, 2026)[0].coverage, 0)
        self.assertEqual(spatial(Space("x", 1, False, "SE"), 2026)[0].coverage, 0)
        self.assertEqual(spatial(Space("x", 1, True), 2026)[0].coverage, 0)

    def test_space_direction_and_location_not_confused(self):
        personal, _ = spatial(Space("x", 1, True, seat_heading=135, seat_error=2, personal_gua=1), 2026)
        self.assertAlmostEqual(personal.coverage, .40)
        sector_only, _ = spatial(Space("x", 1, True, "SE"), 2026)
        self.assertAlmostEqual(sector_only.coverage, .30 * .20)

    def test_house_sitting_not_facing(self):
        e, details = spatial(Space("x", 1, True, "SE", house_facing=180, house_error=2), 2026)
        self.assertEqual(details["house_sector"], "sheng_qi")  # S-facing => N-sitting => Kan.
        self.assertAlmostEqual(e.coverage, .30 + .30 * .20)

    def test_invalid_flying_chart_and_mixed_north(self):
        with self.assertRaises(ValueError):
            spatial(Space("x", 1, True, "SE"), 2026, {"mountain": {x: 1 for x in LUOSHU_PATH}, "water": lo_shu(2)})
        with self.assertRaises(ValueError):
            spatial(Space("x", 1, True, north_reference="true"), 2026)

    def test_full_spatial_coverage(self):
        e, _ = spatial(Space("x", 1, True, "SE", 135, 2, 180, 2, 1), 2026, {"mountain": lo_shu(3), "water": lo_shu(4)})
        self.assertAlmostEqual(e.coverage, 1)

    def test_moon_geometry(self):
        _, new = cosmic(0, 0)
        _, full = cosmic(0, 180)
        waxing, half = cosmic(0, 90)
        waning, _ = cosmic(0, 270)
        self.assertEqual(new["illumination_approx"], 0)
        self.assertEqual(full["illumination_approx"], 1)
        self.assertAlmostEqual(half["illumination_approx"], .5)
        self.assertGreater(waxing.a, 0)
        self.assertLess(waning.a, 0)

    def test_cosmic_missing_motion_stationary(self):
        self.assertEqual(cosmic()[0].coverage, 0)
        e, details = cosmic(mercury_speed=0)
        self.assertAlmostEqual(e.coverage, .2)
        self.assertEqual(details["mercury_motion"], "stationary")
        self.assertEqual(cosmic(mercury_speed=-.2)[1]["mercury_motion"], "retrograde")

    def test_group_weights_and_bounded_optional_effect(self):
        self.assertAlmostEqual(sum(WEIGHTS.values()), 1)
        self.assertAlmostEqual(combine_v2({"F": Evidence(1, 1, 1)}).a, .1)
        self.assertAlmostEqual(combine_v2({"U": Evidence(1, 1, 1)}).a, .05)

    def test_randomized_aggregation(self):
        rng = random.Random(22)
        for _ in range(5000):
            inputs = {k: Evidence(rng.uniform(-1, 1), rng.uniform(-1, 1), rng.random()) for k in WEIGHTS}
            e = combine_v2(inputs)
            self.assertEqual(e, combine_v2(inputs))
            self.assertEqual(sum(reading(e)["percentages"].values()), 100)


if __name__ == "__main__":
    unittest.main(verbosity=2)
