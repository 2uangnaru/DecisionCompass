"""Research scoring extension, 2.0-alpha. Symbolic interpretation, not prediction.

Consumes normalized chart/ephemeris inputs; does not calculate birth charts,
time zones, or house natal Flying-Star charts from raw dates/addresses.
See Decision_Compass_Formula_v2.md for sources and explicit scope boundaries.
"""
from dataclasses import dataclass
from math import sin, cos, radians, isfinite, floor
from decision_formula_reference import (
    Evidence, branch_pair, clamp, digits, mix, r9, reading, TRANSFORMS,
)

VERSION = "2.0-alpha"
WEIGHTS = {"B": .20, "Z": .20, "T": .10, "W": .20, "N": .15, "U": .05, "F": .10}
HIDDEN = {
    0: (9,), 1: (5, 9, 7), 2: (0, 2, 4), 3: (1,),
    4: (4, 1, 9), 5: (2, 6, 4), 6: (3, 5), 7: (5, 3, 1),
    8: (6, 8, 4), 9: (7,), 10: (4, 7, 3), 11: (8, 0),
}
# Equal shares among hidden stems: an explicit product simplification, NOT
# a claimed traditional seasonal hidden-stem strength table.
GODS = {
    "peer": (.10, -.25), "competitor": (.05, .25),
    "expression": (.30, .25), "challenge": (.10, .40),
    "opportunity": (.20, .35), "stewardship": (.15, -.20),
    "pressure": (-.25, .20), "responsibility": (.10, -.15),
    "reflection": (-.20, -.10), "support": (.20, -.20),
}
GOD_PAIRS = {
    0: ("peer", "competitor"), 1: ("expression", "challenge"),
    2: ("opportunity", "stewardship"), 3: ("pressure", "responsibility"),
    4: ("reflection", "support"),
}
BAZI_LAYERS = {"decade": .10, "yearly": .15, "monthly": .15, "daily": .30, "hourly": .30}
ZIWEI_LAYERS = {"natal": .15, "decade": .15, "yearly": .15, "monthly": .10, "daily": .20, "hourly": .25}
MAJOR = {
    "ziwei": (.20, -.20), "tianji": (.10, .50), "taiyang": (.30, .20),
    "wuqu": (.25, -.20), "tiantong": (-.10, -.35), "lianzhen": (.10, .25),
    "tianfu": (.20, -.50), "taiyin": (-.10, -.25), "tanlang": (.15, .50),
    "jumen": (-.15, .20), "tianxiang": (.15, -.40), "tianliang": (.10, -.45),
    "qisha": (.10, .55), "pojun": (-.10, .65),
}
AUX = {
    "zuofu": (.20, -.10), "youbi": (.20, -.10), "wenchang": (.20, 0),
    "wenqu": (.20, 0), "tiankui": (.20, -.10), "tianyue": (.20, -.10),
    "qingyang": (-.25, .20), "tuoluo": (-.25, -.10), "huoxing": (-.25, .20),
    "lingxing": (-.25, .15), "dikong": (-.25, .30), "dijie": (-.25, .30),
}
BRIGHTNESS = {"miao": 1, "wang": .95, "de": .85, "li": .80, "ping": .70, "bu": .60, "xian": .50}
PALACES = {"general": "life", "other": "life", "love": "spouse", "career": "career", "money": "wealth", "relationships": "friends"}
SECTORS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
TRIGRAM = {1: 0b010, 2: 0b000, 3: 0b100, 4: 0b011, 6: 0b111, 7: 0b110, 8: 0b001, 9: 0b101}
SECTOR_GUA = {"N": 1, "NE": 8, "E": 3, "SE": 4, "S": 9, "SW": 2, "W": 7, "NW": 6}
WANDERING = {0: "fu_wei", 1: "sheng_qi", 6: "tian_yi", 7: "yan_nian", 4: "huo_hai", 3: "wu_gui", 5: "liu_sha", 2: "jue_ming"}
MANSION_SCORE = {
    "sheng_qi": (.50, .15), "tian_yi": (.30, -.15), "yan_nian": (.35, -.25),
    "fu_wei": (.20, -.40), "huo_hai": (-.15, 0), "wu_gui": (-.30, .10),
    "liu_sha": (-.25, .10), "jue_ming": (-.40, 0),
}
LUOSHU_PATH = ("C", "NW", "W", "NE", "S", "N", "SW", "E", "SE")


def integer(value, low, high):
    if type(value) is not int or not low <= value <= high:
        raise ValueError(f"Expected integer in [{low},{high}]")
    return value


def normalized_blend(parts):
    """Returns vector conditional on available features, and coverage separately.
    Multiplying vector by coverage later preserves missing contributions as zero.
    """
    q = sum(w * e.coverage for w, e in parts)
    if q == 0:
        return Evidence()
    a, c = mix((w * e.coverage / q, e.vector) for w, e in parts)
    return Evidence(clamp(a), clamp(c), min(1, q))


@dataclass(frozen=True)
class Pillar:
    stem: int
    branch: int

    def __post_init__(self):
        integer(self.stem, 0, 9)
        integer(self.branch, 0, 11)
        if self.stem % 2 != self.branch % 2:
            raise ValueError("Impossible stem/branch parity")


def ten_god(day_stem, other_stem):
    integer(day_stem, 0, 9)
    integer(other_stem, 0, 9)
    delta = (other_stem // 2 - day_stem // 2) % 5
    return GOD_PAIRS[delta][0 if day_stem % 2 == other_stem % 2 else 1]


def pillar_elements(pillar):
    result = [0.0] * 5
    result[pillar.stem // 2] += .40
    for stem in HIDDEN[pillar.branch]:
        result[stem // 2] += .60 / len(HIDDEN[pillar.branch])
    return result


def bazi_profile(natal):
    if len(natal) != 4:
        raise ValueError("Expected year/month/day/hour pillars")
    if natal[2] is None:
        return None
    day_stem = natal[2].stem
    weights = (1, 1.5, 1, 1)
    mass = [0.0] * 5
    used = 0
    gods = []
    for weight, pillar in zip(weights, natal):
        if pillar is None:
            gods.append(None)
            continue
        used += weight
        for i, value in enumerate(pillar_elements(pillar)):
            mass[i] += weight * value
        gods.append({"stem": ten_god(day_stem, pillar.stem), "hidden": [ten_god(day_stem, s) for s in HIDDEN[pillar.branch]]})
    mass = [x / used for x in mass]
    dm = day_stem // 2
    branches = {p.branch for p in natal if p is not None}
    triples = [(8, 0, 4), (11, 3, 7), (2, 6, 10), (5, 9, 1)]
    return {
        "day_stem": day_stem, "element_distribution": mass,
        "support_index": mass[dm] + mass[(dm - 1) % 5],
        "coverage": used / sum(weights), "ten_gods": gods,
        "complete_three_harmony_sets": [list(t) for t in triples if set(t) <= branches],
        "note": "distribution is a product index, not a Yong Shen or strength verdict",
    }


def bazi_expanded(natal, timing, favorable_elements=None):
    """Optional favorable_elements must come from a reviewed external rulebook.
    This function never invents useful/favorable gods from missing elements.
    """
    profile = bazi_profile(natal)
    if profile is None:
        return Evidence(), {"missing": "day pillar"}
    if set(timing) - set(BAZI_LAYERS):
        raise ValueError("Unknown timing layer")
    if favorable_elements is not None:
        if set(favorable_elements) != set(range(5)) or any(not isfinite(v) or abs(v) > 1 for v in favorable_elements.values()):
            raise ValueError("Reviewed favorable element map must contain five bounded values")
    dm = profile["day_stem"]
    known = [(w, p) for w, p in zip((.1, .2, .5, .2), natal) if p is not None]
    nq = sum(w for w, _ in known)
    layers = []
    for name, p in timing.items():
        stems = [(.4, p.stem)] + [(.6 / len(HIDDEN[p.branch]), s) for s in HIDDEN[p.branch]]
        gv = mix((w, GODS[ten_god(dm, s)]) for w, s in stems)
        bv = mix((w / nq, branch_pair(p.branch, n.branch)) for w, n in known)
        fav = Evidence()
        if favorable_elements is not None:
            fav = Evidence(sum(w * favorable_elements[s // 2] for w, s in stems), 0, 1)
        e = normalized_blend([(.55, Evidence(*gv, 1)), (.30, Evidence(*bv, 1)), (.15, fav)])
        e = Evidence(e.a, e.c, e.coverage * profile["coverage"])
        layers.append((BAZI_LAYERS[name], e))
    return normalized_blend(layers), profile


@dataclass(frozen=True)
class Star:
    name: str
    palace: int
    brightness: str | None = None

    def __post_init__(self):
        integer(self.palace, 0, 11)
        if self.name not in MAJOR and self.name not in AUX:
            raise ValueError("Unsupported star; adapter must preserve it as unscored metadata")
        if self.brightness is not None and self.brightness not in BRIGHTNESS:
            raise ValueError("Unknown brightness")


def proximity(palace, target):
    integer(palace, 0, 11)
    integer(target, 0, 11)
    return {0: 1, 4: .6, 8: .6, 6: .5}.get((palace - target) % 12, 0)


def ziwei_expanded(stars, targets, layers, category="general", birth_time_known=True):
    if not birth_time_known:
        return Evidence(), {"missing": "birth time"}
    if set(layers) - set(ZIWEI_LAYERS):
        raise ValueError("Unknown Zi Wei layer")
    target = targets[PALACES[category]]
    integer(target, 0, 11)
    by_name = {s.name: s for s in stars}
    if len(by_name) != len(stars):
        raise ValueError("Duplicate star in chart")
    parts = []
    for weight, catalog, divisor in ((.45, MAJOR, 4), (.20, AUX, 3)):
        selected = [s for s in stars if s.name in catalog]
        # A chart adapter must send the complete catalog to call a component available.
        if {s.name for s in selected} != set(catalog) or (catalog is MAJOR and any(s.brightness is None for s in selected)):
            parts.append((weight, Evidence()))
            continue
        # Auxiliary stars may not have a brightness class in the selected school.
        vec = mix((proximity(s.palace, target) * (BRIGHTNESS[s.brightness] if s.brightness is not None else 1) / divisor, catalog[s.name]) for s in selected)
        parts.append((weight, Evidence(clamp(vec[0]), clamp(vec[1]), 1)))
    transformed = []
    for name, data in layers.items():
        # Each layer explicitly supplies its own target index and star placements.
        layer_target = data["target"]
        integer(layer_target, 0, 11)
        events = data["events"]
        if len(events) != 4 or {event["kind"] for event in events} != set(TRANSFORMS):
            raise ValueError("Layer must have exactly four transformations")
        vec = mix((proximity(event["palace"], layer_target) / 2, TRANSFORMS[event["kind"]]) for event in events)
        transformed.append((ZIWEI_LAYERS[name], Evidence(clamp(vec[0]), clamp(vec[1]), 1)))
    parts.append((.35, normalized_blend(transformed)))
    return normalized_blend(parts), {"scored_major": len(set(by_name) & set(MAJOR)), "scored_auxiliary": len(set(by_name) & set(AUX)), "layers": list(layers)}


def life_gua(solar_birth_year, traditional_sex):
    """Year already resolved at exact Li Chun by calendar adapter, not Jan 1."""
    integer(solar_birth_year, 1900, 2099)
    if traditional_sex not in ("male", "female"):
        return None
    year_digit = r9(digits(solar_birth_year))
    number = r9(11 - year_digit) if traditional_sex == "male" else r9(4 + year_digit)
    return (2 if traditional_sex == "male" else 8) if number == 5 else number


def bearing_sector(degrees, uncertainty=0):
    if not all(isfinite(x) for x in (degrees, uncertainty)) or uncertainty < 0:
        raise ValueError("Invalid compass reading")
    degrees %= 360
    pos = (degrees + 22.5) % 45
    margin = min(pos, 45 - pos)
    if uncertainty >= margin:
        return None
    return SECTORS[int((degrees + 22.5) // 45) % 8]


def mansion(gua, sector):
    return WANDERING[TRIGRAM[gua] ^ TRIGRAM[SECTOR_GUA[sector]]]


def lo_shu(center, forward=True):
    integer(center, 1, 9)
    if type(forward) is not bool:
        raise ValueError("Flight direction must be bool")
    step = 1 if forward else -1
    return {sector: (center - 1 + step * i) % 9 + 1 for i, sector in enumerate(LUOSHU_PATH)}


def annual_center(solar_year):
    integer(solar_year, 1900, 2099)
    return r9(11 - r9(digits(solar_year)))


def period_number(solar_year):
    integer(solar_year, 1864, 2103)
    return ((solar_year - 1864) // 20) % 9 + 1


def star_timeliness(star, period):
    integer(star, 1, 9)
    integer(period, 1, 9)
    return {0: .5, 1: .25, 2: .1}.get((star - period) % 9, -.2)


@dataclass(frozen=True)
class Space:
    space_id: str
    revision: int
    active: bool
    room_sector: str | None = None
    seat_heading: float | None = None
    seat_error: float | None = None
    house_facing: float | None = None
    house_error: float | None = None
    personal_gua: int | None = None
    north_reference: str = "magnetic"
    chart_north_reference: str = "magnetic"


def spatial(space, solar_year, natal_flying=None):
    """natal_flying optionally contains reviewed mountain/water 9-palace maps.
    No automatic house chart, no GPS-derived floor location, no sensor access.
    """
    if space is None or not space.active:
        return Evidence(), {"missing": "active space"}
    if space.north_reference not in ("magnetic", "true") or space.north_reference != space.chart_north_reference:
        raise ValueError("Compass references differ; convert explicitly first")
    if space.room_sector is not None and space.room_sector not in SECTORS + ("C",):
        raise ValueError("Invalid room sector")
    if space.personal_gua is not None and space.personal_gua not in TRIGRAM:
        raise ValueError("Invalid personal gua")
    personal = Evidence()
    house = Evidence()
    fly = Evidence()
    details = {"space_id": space.space_id, "revision": space.revision}
    if space.personal_gua is not None and space.seat_heading is not None and space.seat_error is not None:
        sector = bearing_sector(space.seat_heading, space.seat_error)
        if sector is not None:
            label = mansion(space.personal_gua, sector)
            personal = Evidence(*MANSION_SCORE[label], 1)
            details["personal_direction"] = label
    if space.house_facing is not None and space.house_error is not None and space.room_sector in SECTORS:
        sitting = bearing_sector(space.house_facing + 180, space.house_error)
        if sitting is not None:
            label = mansion(SECTOR_GUA[sitting], space.room_sector)
            house = Evidence(*MANSION_SCORE[label], 1)
            details["house_sector"] = label
    if space.room_sector is not None:
        period = period_number(solar_year)
        annual = lo_shu(annual_center(solar_year))[space.room_sector]
        details["annual_star"] = annual
        components = [(.20, Evidence(star_timeliness(annual, period), 0, 1))]
        if natal_flying is not None:
            for layer in ("mountain", "water"):
                chart = natal_flying[layer]
                if set(chart) != set(LUOSHU_PATH) or sorted(chart.values()) != list(range(1, 10)):
                    raise ValueError("Flying chart layer must contain a permutation of 1..9")
                components.append((.40, Evidence(star_timeliness(chart[space.room_sector], period), 0, 1)))
        fly = normalized_blend(components)
    return normalized_blend([(.40, personal), (.30, house), (.30, fly)]), details


def cosmic(sun_longitude=None, moon_longitude=None, mercury_speed=None):
    """Real geometric features; their score interpretation is editorial only.
    Longitudes: geocentric tropical degrees. Mercury speed: degrees/day.
    """
    phase = Evidence()
    motion = Evidence()
    details = {}
    for value in (sun_longitude, moon_longitude):
        if value is not None and (not isfinite(value) or not 0 <= value < 360):
            raise ValueError("Longitude outside [0,360)")
    if sun_longitude is not None and moon_longitude is not None:
        angle = (moon_longitude - sun_longitude) % 360
        phase = Evidence(.35 * sin(radians(angle)), .25 * cos(radians(angle)), 1)
        details.update(elongation=angle, illumination_approx=(1 - cos(radians(angle))) / 2)
    if mercury_speed is not None:
        if not isfinite(mercury_speed):
            raise ValueError("Non-finite motion")
        movement = clamp(mercury_speed / .10)
        motion = Evidence(.15 * movement, .10 * movement, 1)
        details["mercury_motion"] = "stationary" if abs(mercury_speed) <= .01 else "retrograde" if mercury_speed < 0 else "direct"
    return normalized_blend([(.80, phase), (.20, motion)]), details


def combine_v2(modules):
    if set(modules) - set(WEIGHTS):
        raise ValueError("Unknown or duplicate-v1 module")
    a, c = mix((WEIGHTS[name] * e.coverage, e.vector) for name, e in modules.items())
    coverage = sum(WEIGHTS[name] * e.coverage for name, e in modules.items())
    return Evidence(clamp(a), clamp(c), min(1, coverage))


if __name__ == "__main__":
    import json
    # Entirely synthetic features, not a real person's birth chart or today's sky.
    b, _ = bazi_expanded([Pillar(0, 0), Pillar(2, 2), Pillar(4, 4), Pillar(6, 6)], {"daily": Pillar(8, 8), "hourly": Pillar(0, 0)})
    u, sky = cosmic(0, 90, -.3)
    f, room = spatial(Space("demo-only", 1, True, "SE", 135, 2, 180, 2, 1), 2026)
    e = combine_v2({"B": b, "U": u, "F": f})
    print(json.dumps({"synthetic_only": True, "version": VERSION, "reading": reading(e), "sky": sky, "space": room}, indent=2))
