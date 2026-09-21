"""Test-only bridge to the original Python formulas, never a runtime dependency."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "outputs"))
from datetime import date
from decision_formula_reference import numerology, almanac, western
from decision_formula_v2 import (
    Pillar, Star, bazi_expanded, ziwei_expanded, cosmic, combine_v2
)

data = json.load(sys.stdin)
out = []
for case in data:
    modules = {}
    modules["N"] = numerology(date.fromisoformat(case["birth_date"]), date.fromisoformat(case["date"]))[0]
    modules["T"] = almanac(*case["almanac"])
    modules["B"] = bazi_expanded(
        [Pillar(*p) if p is not None else None for p in case["pillars"]],
        {k: Pillar(*p) for k, p in case["timing"].items()},
    )[0]
    modules["Z"] = ziwei_expanded(
        [Star(*s) for s in case["stars"]], {"life": case["target"]}, case["layers"]
    )[0]
    modules["W"] = western(case["transits"], case["natal"])
    modules["U"] = cosmic(*case["cosmic"])[0]
    combined = combine_v2(modules)
    out.append({
        "modules": {k: {"a": v.a, "c": v.c, "coverage": v.coverage} for k, v in modules.items()},
        "fusion": {"a": combined.a / .9, "c": combined.c / .9, "coverage": combined.coverage / .9},
    })
json.dump(out, sys.stdout)
