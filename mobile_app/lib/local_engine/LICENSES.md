# Offline engine — provenance, attribution and licensing

Everything under `lib/local_engine/` is a Dart port of the deterministic
calculation engine in `../../../calculation-engine/`, which remains the
mathematical reference. No AI, no network call and no random value takes part
in a reading.

The `*_data.dart` files are **generated**, not hand-written: the scripts in
`calculation-engine/scripts/port/` read the pinned upstream packages in
`node_modules` and re-emit their tables verbatim, so the Dart engine and the
Node engine compute from identical numbers. Re-run them after bumping a
provider version:

```powershell
node scripts/port/gen_tzdb.mjs
node scripts/port/gen_astronomy.mjs
node scripts/port/gen_calendar.mjs
node scripts/port/gen_ziwei.mjs
```

The matching parity corpora under `mobile_app/test/local_engine/` come from the
same place:

```powershell
node scripts/port/gen_time_corpus.mjs
node scripts/port/gen_astronomy_corpus.mjs
node scripts/port/gen_calendar_corpus.mjs
node scripts/port/gen_bazi_corpus.mjs
node scripts/port/gen_ziwei_corpus.mjs
node scripts/port/gen_edge_readings.mjs
```

## Bundled algorithms and data

| Source | Version | Licence | What was ported | Where |
|---|---|---|---|---|
| [Astronomy Engine](https://github.com/cosinekitty/astronomy) © Don Cross | 2.1.19 | MIT | ΔT, IAU 2000B nutation, IAU 2006 precession, VSOP87 series for Mercury–Saturn, the Montenbruck/Pfleger lunar series, light-time and aberration | `astronomy/` |
| [lunar-javascript](https://github.com/6tail/lunar-javascript) © 6tail | 1.7.7 | MIT | 寿星天文历 solar-term and new-moon series, lunar year/month construction, day pillar, 天神 tables | `calendar/` |
| [iztro](https://github.com/SylarLong/iztro) © SylarLong | 2.6.1 | MIT | Zi Wei palace layout, 14 major and 12 auxiliary stars, brightness, 四化, five horoscope layers | `ziwei/` |
| [lunar-lite](https://github.com/SylarLong/lunar-lite) © SylarLong | 0.2.8 | MIT | The stem/branch helpers iztro calls | `ziwei/lunar_lite.dart` |
| [Moment Timezone](https://momentjs.com/timezone/) | 0.6.4, tzdb **2026d** | MIT | The packed IANA database, its links and its country mapping, plus moment's own offset semantics | `time/` |

Upstream copyright notices are retained in the header of each ported file.
Only the subset the engine actually reaches was ported; the rest of each
library is intentionally absent, so the APK carries no table it cannot use.

SHA-256 is implemented directly in `core/sha256.dart` rather than pulled from a
package, so the engine adds no runtime dependency at all.

## Bundle size

| Asset | Source size | Notes |
|---|---:|---|
| `time/tzdb_data.dart` | ~717 KB | Packed tzdb 2026d: 344 zones, 253 links, 247 countries |
| `calendar/calendar_data.dart` | ~80 KB | XL0/XL1 series, ΔT and keyframe tables, decoded correction strings |
| `astronomy/astronomy_data.dart` | ~26 KB | 360 VSOP terms across six bodies, 114 lunar series rows |
| `ziwei/ziwei_data.dart` | ~4 KB | Star, brightness and 四化 tables |

About 830 KB of Dart source in total. Measured impact on the packaged app, by
building a release APK twice with only `main.dart` swapped between the HTTP
repository and the local engine:

| Release APK | Size |
|---|---:|
| Without the engine (tree-shaken out) | 55,335,522 B — 52.8 MB |
| With the engine | 57,514,594 B — 54.9 MB |
| **Impact** | **+2,179,072 B — +2.08 MB, +3.9 %** |

The AOT snapshot stores the packed tzdb strings as UTF-16 and the numeric
series as unpacked doubles, which is why the installed cost is larger than the
source. Dropping the pre-1970 half of the tzdb would recover most of it if that
ever matters; it is kept because birth years start at 1900.

## Not bundled: timezone geometry

The Node engine narrows the current timezone from a position fix with
[geo-tz](https://github.com/evansiroky/node-geo-tz) (MIT code), whose dataset
comes from
[timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder)
and is licensed
[ODbL](https://github.com/evansiroky/timezone-boundary-builder/blob/master/DATA_LICENSE),
with contributions from [OpenStreetMap](https://www.openstreetmap.org/copyright).

It is **not** bundled here, for two reasons:

1. **Size.** The variant the engine uses is a 30 MB geobuf plus a 0.9 MB index.
   That is roughly forty times the rest of the offline engine and would
   dominate the download.
2. **Licensing.** ODbL is a share-alike licence for the database itself.
   Redistributing it inside a commercial app is possible, but it carries
   attribution and share-alike obligations that are a product and legal
   decision, not an implementation detail.

`location/location.dart` therefore exposes a `ZoneGeometryResolver` seam with no
default implementation. Every other branch of the Node engine's location logic
is reproduced exactly — no fix, an invalid fix, a stale fix — and a *valid,
fresh* fix reports `locationStatus: "zone_lookup_unavailable"` with the warning
`location_zone_lookup_unavailable_using_device`, falling back to the device
timezone. Nothing is guessed, and the reading is not blocked.

Both fields are free-form strings in `calculation-engine/src/index.d.ts`
(`locationStatus: string`, `warnings: string[]`) and in the Dart DTO, so this
stays inside the existing contract.

Installing the dataset later restores full parity without touching the engine:
implement `ZoneGeometryResolver` and pass it to `calculate`.

## Independent calendar and astronomy references

The cross-checks listed in `calculation-engine/THIRD_PARTY.md` (HKO calendars
and almanacs, USNO equinoxes and solstices) apply unchanged: they validate the
calendrical and physical features, never the symbolic scores. The A/C weights,
scenario-coverage caps and percentage mapping are editorial product rules and
are not validated against anything in the real world.
