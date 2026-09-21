"""Symbolic scoring prototype. NOT a calendar/chart calculator or predictor.

All scoring coefficients are editorial v1-alpha choices. Provider features must
be validated separately; no external packages, network, AI, or user data used.
"""
from dataclasses import dataclass
from datetime import date
from math import floor, isfinite

VERSION = "1.0-alpha"
WEIGHTS = {"B": .20, "Z": .175, "T": .125, "W": .30, "N": .20}
NUMBERS = {
    1: (.6, .6), 2: (-.2, -.3), 3: (.4, .2), 4: (.1, -.6),
    5: (.3, .7), 6: (.1, -.5), 7: (-.6, -.2), 8: (.5, .1), 9: (-.2, .6),
}
OFFICERS = {
    "establish": (.3, .3), "remove": (.1, .7), "full": (.1, -.3),
    "balance": (0, 0), "stable": (.2, -.7), "hold": (.1, -.6),
    "break": (-.5, .7), "danger": (-.5, 0), "success": (.5, .2),
    "receive": (.3, -.3), "open": (.4, .6), "close": (-.3, -.5),
}
TRANSFORMS = {"lu": (.35, -.1), "quan": (.2, .2), "khoa": (.25, -.2), "ky": (-.45, .15)}
LAYERS = {"natal": .20, "yearly": .15, "monthly": .15, "daily": .25, "hourly": .25}
TRANSIT = {"moon": .35, "sun": .15, "mercury": .1, "venus": .1, "mars": .1, "jupiter": .1, "saturn": .1}
NATAL = {
    "general": {"sun": .3, "moon": .3, "mercury": .1, "venus": .1, "mars": .1, "jupiter": .05, "saturn": .05},
    "love": {"moon": .35, "venus": .4, "mercury": .15, "mars": .1},
    "career": {"sun": .25, "mercury": .25, "mars": .2, "saturn": .2, "jupiter": .1},
    "money": {"jupiter": .3, "saturn": .3, "venus": .2, "mercury": .2},
    "relationships": {"moon": .2, "venus": .25, "mercury": .4, "sun": .15},
}
CONJ_CHANGE = {"moon": 0, "sun": .1, "mercury": .2, "venus": -.1, "mars": .4, "jupiter": .3, "saturn": -.4}
ASPECTS = {60: (.5, .2), 90: (-.5, .3), 120: (.6, -.3), 180: (-.6, .3)}


def clamp(value):
    return max(-1.0, min(1.0, value))


def mix(items):
    """Weighted sum, deliberately NOT normalized."""
    rows = list(items)
    return tuple(sum(w * v[axis] for w, v in rows) for axis in (0, 1))


@dataclass(frozen=True)
class Evidence:
    a: float = 0
    c: float = 0
    coverage: float = 0

    def __post_init__(self):
        if not all(isfinite(x) for x in (self.a, self.c, self.coverage)):
            raise ValueError("Non-finite feature")
        if not (-1 <= self.a <= 1 and -1 <= self.c <= 1 and 0 <= self.coverage <= 1):
            raise ValueError("Feature out of bounds")

    @property
    def vector(self):
        return self.a, self.c


def r9(n):
    if not isinstance(n, int) or n < 1:
        raise ValueError("Expected positive integer")
    return 1 + (n - 1) % 9


def digits(n):
    return sum(int(c) for c in str(n))


def numerology(birth: date, current: date):
    if birth > current:
        raise ValueError("Birth date is in the future")
    lp = r9(digits(birth.year) + digits(birth.month) + digits(birth.day))
    py = r9(birth.month + birth.day + digits(current.year))
    pm = r9(py + current.month)
    pd = r9(pm + current.day)
    a, c = mix(zip((.10, .15, .25, .50), (NUMBERS[n] for n in (lp, py, pm, pd))))
    return Evidence(a, c, 1), {"life_path": lp, "personal_year": py, "personal_month": pm, "personal_day": pd}


def hour_branch(local_hour):
    if not isinstance(local_hour, int) or not 0 <= local_hour < 24:
        raise ValueError("Hour must be 0..23")
    return ((local_hour + 1) // 2) % 12


def hour_stem(day_stem, local_hour):
    if not isinstance(day_stem, int) or not 0 <= day_stem < 10:
        raise ValueError("Stem must be 0..9")
    return (2 * (day_stem % 5) + hour_branch(local_hour)) % 10


def element_pair(incoming, personal):
    # Elements 0..4 = Wood, Fire, Earth, Metal, Water (generation cycle).
    if incoming not in range(5) or personal not in range(5):
        raise ValueError("Unknown element")
    delta = (incoming - personal) % 5
    return {0: (.2, -.3), 4: (.4, -.2), 1: (.2, .4), 2: (0, .2), 3: (-.4, 0)}[delta]


def branch_pair(a, b):
    if a not in range(12) or b not in range(12):
        raise ValueError("Unknown branch")
    if a == b:
        return .1, -.2
    if (a - b) % 12 == 6:
        return -.5, .5
    if frozenset((a, b)) in {frozenset(x) for x in ((0, 1), (2, 11), (3, 10), (4, 9), (5, 8), (6, 7))}:
        return .5, -.4
    return 0, 0


def bazi_basic(day_master_element, natal_branches, current_day, current_hour):
    """Current pillars are (stem_element, branch); natal order year/month/day/hour.
    Provider must have resolved the calendar. Not a full BaZi reading.
    """
    if len(natal_branches) != 4:
        raise ValueError("Expected four natal branch positions")
    if day_master_element is None or natal_branches[2] is None:
        return Evidence()
    known = [(w, b) for w, b in zip((.1, .2, .5, .2), natal_branches) if b is not None]
    q = sum(w for w, _ in known)
    vectors = []
    for el, branch in (current_day, current_hour):
        relation = mix((w / q, branch_pair(branch, b)) for w, b in known)
        vectors.append(mix(((.6, element_pair(el, day_master_element)), (.4, relation))))
    a, c = mix(zip((.4, .6), vectors))
    return Evidence(a, c, min(1, q))


def almanac(day_auspicious, hour_auspicious, officer):
    if day_auspicious is None or hour_auspicious is None or officer is None:
        return Evidence()
    if type(day_auspicious) is not bool or type(hour_auspicious) is not bool:
        raise ValueError("Auspicious flags must be booleans")
    a, c = OFFICERS[officer]
    day = .5 if day_auspicious else -.5
    hour = .5 if hour_auspicious else -.5
    return Evidence(.25 * day + .4 * hour + .35 * a, c, 1)


def ziwei(layers):
    """Each valid layer contains 4 (transformation_id, palace_distance) tuples.
    Provider computes actual chart/star locations and category target palace.
    """
    if set(layers) - set(LAYERS):
        raise ValueError("Unknown layer")
    weighted = []
    q = 0
    for name, events in layers.items():
        if len(events) != 4 or {e[0] for e in events} != set(TRANSFORMS):
            raise ValueError("Each supplied layer must contain all four transformations")
        parts = []
        for kind, distance in events:
            if not isinstance(distance, int) or distance not in range(12):
                raise ValueError("Palace distance must be 0..11")
            proximity = {0: 1, 4: .6, 8: .6, 6: .5}.get(distance, 0)
            parts.append((proximity / 2, TRANSFORMS[kind]))
        vector = tuple(clamp(x) for x in mix(parts))
        weighted.append((LAYERS[name], vector))
        q += LAYERS[name]
    if q == 0:
        return Evidence()
    a, c = mix(weighted)
    return Evidence(a / q, c / q, min(1, q))


def aspect_vector(transit_lon, natal_lon, planet):
    if not all(isfinite(x) and 0 <= x < 360 for x in (transit_lon, natal_lon)):
        raise ValueError("Longitude must be finite and in [0,360)")
    d = abs((transit_lon - natal_lon + 180) % 360 - 180)
    angle = min((0, 60, 90, 120, 180), key=lambda x: abs(d - x))
    strength = max(0, 1 - abs(d - angle) / 3)
    base = (0, CONJ_CHANGE[planet]) if angle == 0 else ASPECTS[angle]
    return tuple(strength * v for v in base)


def western(transits, natal, category="general"):
    weights = NATAL["general" if category == "other" else category]
    q = 0
    parts = []
    for p, pw in TRANSIT.items():
        for n, nw in weights.items():
            if transits.get(p) is None or natal.get(n) is None:
                continue
            w = pw * nw
            q += w
            parts.append((w, aspect_vector(transits[p], natal[n], p)))
    if q == 0:
        return Evidence()
    a, c = mix(parts)
    return Evidence(clamp(3 * a / q), clamp(3 * c / q), min(1, q))


def combine(modules):
    if set(modules) - set(WEIGHTS):
        raise ValueError("Unknown module")
    a, c = mix((WEIGHTS[name] * e.coverage, e.vector) for name, e in modules.items())
    coverage = sum(WEIGHTS[name] * e.coverage for name, e in modules.items())
    return Evidence(clamp(a), clamp(c), min(1, coverage))


def percent(score):
    if not isfinite(score) or not -1 <= score <= 1:
        raise ValueError("Score outside [-1,1]")
    return floor(50 + 40 * score + .5)


def reading(e, mode="yes_no"):
    if e.coverage == 0:
        return {"status": "insufficient_data", "consume_unlock": False}
    mappings = {
        "yes_no": ("YES", "NO", e.a), "act_wait": ("ACT", "WAIT", e.a),
        "advance_retreat": ("ADVANCE", "RETREAT", e.a),
        "stay_go": ("STAY", "GO", -e.c), "keep_let_go": ("KEEP", "LET GO", -e.c),
    }
    first, second, score = mappings[mode]
    p = percent(score)
    return {
        "status": "balanced" if p == 50 else "ready",
        "winner": None if p == 50 else first if p > 50 else second,
        "percentages": {first: p, second: 100 - p},
        "coverage": e.coverage, "limited_details": e.coverage < .5,
        "meaning": "symbolic_alignment_not_success_probability",
    }


def duration_average(segments):
    """Adapter supplies disjoint UTC durations and vectors; use for slots/periods."""
    if not segments or any(not isfinite(d) or d <= 0 for d, _ in segments):
        raise ValueError("Expected positive segment durations")
    total = sum(d for d, _ in segments)
    a, c = mix((d / total, e.vector) for d, e in segments)
    coverage = sum(d / total * e.coverage for d, e in segments)
    return Evidence(clamp(a), clamp(c), min(1, coverage))


def top_two(windows):
    """(utc_start_seconds, utc_end_seconds, already averaged evidence).
    Windows must already be clipped to now/selected period by the adapter.
    """
    result = []
    for start, end, e in windows:
        if not all(isfinite(x) for x in (start, end)) or end <= start:
            raise ValueError("Invalid time window")
        if end - start >= 15 * 60 and e.coverage > 0:
            result.append({"start": start, "end": end, "lucky_score": percent(e.a)})
    return sorted(result, key=lambda r: (-r["lucky_score"], r["start"]))[:2]


if __name__ == "__main__":
    import json
    demo = combine({k: Evidence(v, 0, 1) for k, v in {"B": .3, "Z": .2, "T": .4, "W": .1, "N": .5}.items()})
    print(json.dumps({"synthetic_example_only": True, "version": VERSION, "score": demo.a, "reading": reading(demo)}, indent=2))
