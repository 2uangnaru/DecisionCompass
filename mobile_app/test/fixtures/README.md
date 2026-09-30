# Engine response fixtures — provenance

These JSON files drive the DTO contract tests in `test/data/`. They contain no
real personal data; the birth profile is a synthetic 1998-06-21 / VN profile.

## How these are meant to be maintained

The generator/checker lives in the engine repo and calls the real engine:

```sh
node scripts/mobile-fixtures.mjs --write   # regenerate from engine output
node scripts/mobile-fixtures.mjs --check   # fail if a fixture drifts from the engine
```

It validates every fixture's projection using the engine's own
`MODES` / `percentTenths` / `scoreForMode`, so the formulas are never re-implemented
outside `src/core.js`.

## Status — verified 2026-09-24

The sixteen engine-reproducible fixtures below are **real engine golden
output**, written verbatim by `scripts/mobile-fixtures.mjs --write` on Node
**v24.19.0** against engine `3.5.0-mvp` / ruleset
`civil-midnight-chinese-calendar-symbolic-v8` (daily colour pair and tenths).
`--check` then exited **0**
("All 16 engine fixtures match current engine output"), and the engine suite
passed **111/111** on the same runtime. Flutter analyze was clean and
**455/455** Flutter tests passed after the legacy-history and layout fixes.

Because they are verbatim, they carry fields the DTO deliberately ignores —
`segments` (per-module diagnostics) and the top-level `meaning`, which
`index.d.ts` does not declare. The round-trip test therefore asserts that every
field the DTO *emits* matches the payload, rather than whole-map equality.

Do not hand-edit `percentages`, `modeScore`, `axisScores` or `winner` in these
files. If a value looks wrong, fix the scenario in the generator and re-run
`--write`; `--check` is what keeps them honest.

Every generated ready reading carries `dailyBrief.energy` and the two-colour
`dailyBrief.colors` pair. The two synthetic parser-only files remain
hand-maintained and may omit these fields. Older on-device history snapshots
with only `colorInspiration` are still read and displayed without inventing a
second colour for a past reading.

## Fixtures

| File | Source | Covers |
|---|---|---|
| `ready_yes_no_now.json` | engine | NOW, no windows, `not_applicable`, YES 66.6/33.4 |
| `ready_commit_withdraw_two_windows.json` | engine | evening, `two_available`, COMMIT 67.5/32.5 |
| `ready_left_right.json` | engine | afternoon, `two_available`; LEFT/RIGHT is not an alias of YES/NO, RIGHT 82.8/17.2 |
| `ready_advance_retreat.json` | engine | morning, `two_available`, ADVANCE 71.1/28.9 |
| `ready_act_wait_midday.json` | engine | midday, `two_available`, ACT 57.5/42.5 |
| `one_remaining.json` | engine | evening late, `one_remaining`, LET GO 74.8/25.2 |
| `no_15_minute_window.json` | engine | evening later, `no_15_minute_window`, still `ready` |
| `period_elapsed.json` | engine | elapsed morning: `consumeUnlock:false`, no score/window/day fields at all |
| `unknown_birth_time_warnings.json` | engine | unknown birth hour, `uncertain` + `unknown_birth_time` warnings, reduced coverage |
| `location_fallback_device_timezone.json` | engine | a >15-minute-old fix is rejected (`stale_fix`) and the reading falls back to the device timezone |
| `ready_love_evening.json` | engine | `category: love` — Zi Wei 夫妻/福德 targets, Venus/Moon-weighted Western profile |
| `ready_career_now.json` | engine | `category: career`, ACT/WAIT, NOW |
| `ready_money_afternoon.json` | engine | `category: money`, ADVANCE/RETREAT |
| `ready_study_morning.json` | engine | `category: study`, COMMIT/WITHDRAW |
| `ready_friends_midday.json` | engine | `category: friends` — 仆役/交友 alias resolution |
| `ready_other_now.json` | engine | `category: other` — general formula, distinct snapshot identity |
| `legacy_forward_backward_reading.json` | **legacy — hand-kept** | a real ruleset-v8 reading in the retired `forward_backward` mode |
| `synthetic_balanced.json` | **synthetic — parser only** | `balanced` (exactly 50/50) |
| `synthetic_insufficient_data.json` | **synthetic — parser only** | `insufficient_data`, null percentages/winner |

The two `synthetic_*` files are hand-maintained, so their version strings and
`inputSnapshot.category` are kept aligned with the contract by hand; they are
**not** engine output and the generator never writes them.

`legacy_forward_backward_reading.json` is engine output, but from ruleset v8.
It is frozen deliberately. `forward_backward` was replaced by
`commit_withdraw` in v9.1, which asks a different question from a different
signal, so the engine refuses to compute new readings for it and nothing may
re-derive this one's percentage under today's curve — that would be exactly the
silent relabelling it exists to prevent. The generator skips `legacy_*` files
and instead checks that this one is genuinely old: a retired mode, and a
ruleset string that is not the current one.

Every engine fixture now carries `category` at the top level and inside
`inputSnapshot`, and each module in `segments[].modules` reports the `weight`
the selected category profile gave it.

"engine" above means the file is byte-for-byte what the engine emitted for that
scenario, reproducible with `--write` and verified by `--check`.

## Why the two `synthetic_*` files exist

They are **parser-only fixtures**. They exercise DTO states that the contract
declares but that the generator cannot request on demand:

- `synthetic_insufficient_data.json` — `decision()` only returns
  `insufficient_data` when fused coverage is exactly 0 (`src/core.js`). The
  numerology module scores from `birthDate` alone, which is always present, so
  coverage is never 0 on the normal path. Treat this as a defensive
  parser fixture, **not** a reachable engine state.
- `synthetic_balanced.json` — `balanced` needs `displayTenths(score) == 500`
  (`src/scoring.js`), i.e. a mode score whose expanded magnitude lands inside
  half a tenth of the middle. That is reachable, but not by asking the engine
  for it; it would have to be found by scanning instants. Its numbers are
  self-consistent under the real display curve, but it is not engine output.

Neither file may be presented as engine golden output.
