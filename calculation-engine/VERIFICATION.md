# Verification record — 2026-09-19

Runtime used: Node.js 24.19.0, Python 3.14.7, Windows. Engine 3.0.0-mvp at the time these
checks were executed.
Pinned package versions and tzdb are emitted in every result.

> **Metadata migration note (2026-09-21):** `package.json`, this file's header and
> `README.md` previously lagged `src/core.js`, which already reported `VERSION =
> '3.1.0-mvp'` / `RULESET = 'civil-midnight-chinese-calendar-symbolic-v4'`. Metadata
> strings were normalized to `3.1.0-mvp` to match the running code. No score formula,
> module weight, decision-mode projection or calendar/BaZi/Zi Wei/numerology/astronomy
> logic was changed, and no executable file was touched — the change is limited to
> `package.json`, `README.md` and this header. No test or script reads the
> `package.json` version, so the counts recorded below still describe the current code.
> **Reconfirmed on 2026-09-21:** `node --test test/*.test.js` passed **47/47** on
> Node **v24.19.0** after the metadata change (see the 2026-09-21 run below).

## v9.3 — the timing signal, and a period cutoff — 2026-09-30

Engine **4.2.0-mvp** / ruleset
**`civil-midnight-chinese-calendar-symbolic-v9.3-experimental`**, scales
`v9.3-cohort-2026-09-30`.

### The timing signal was still blind in the evening

v9.2 fixed `T` for a named period by adding the rest of that period to the
comparison set, but left NOW comparing only against periods that had not
started. After 18:00 no period starts, so every NOW reading from six in the
evening to midnight scored a timing of exactly zero — for ACT / WAIT, the mode
that is mostly timing, that is most of an evening's readings decided without
the thing they are about.

Rather than special-case NOW, the comparison set is now the same for every
period: **every boundary hour of the local day after the anchor's own hour**.
"This moment against the rest of today" only ever meant the rest of today.

A consequence: `T` no longer depends on the selected period at all, only on the
anchor's wall hour, so `period` left the signal functions and the score-cache
key again. `periodBoundaryHours` and the period-anchor helper went with it.

Measured across the calibration cohort, `T`'s median absolute raw value moved
0.011 (v9.1) → 0.089 (v9.2) → 0.090 (v9.3), with a tighter upper quartile
(0.129 → 0.109) now that NOW contributes real values all day instead of zeros.
Only `T`'s scale changed; the other eight are byte-identical to v9.2.

Tested at 07:00, 09:00, 11:00, 13:00, 15:00, 17:00, 19:00 and 21:00 local; at
23:00, where zero is the honest answer because nothing follows it; at midnight,
where the whole day is ahead; across all four named periods; and across both
America/New_York daylight-saving transitions. Node and Dart, in both suites.

### The result guidance was claiming a signal it could not know

`act_wait:first` read *"Of the moments this day still offers, this one reads as
the most aligned."* ACT wins on a mixture — `.30P + .10C + .30T + .30L` — so it
can and does win while `T` is negative. `test/scoring.test.js` and
`test/local_engine/scoring_test.dart` both pin a real instant where that
happens.

Five modes made the same class of claim, one per leading signal, and all ten of
their headlines were rewritten in all seven languages. Each now names the
signal the mode leads on, says it was weighed with the rest, and states only
the leaning the mixture actually produced — for example *"Timing counted
alongside everything else, the reading leans toward acting."* YES/NO and
KEEP/LET GO already said "the signals lean toward…", which was always accurate,
and were left alone. `test/action_guidance_test.dart` now fails on a list of
overclaiming phrases.

### Period selection now closes before a period ends

A reading for a period that has twenty minutes left produces windows mostly
behind the reader by the time they read them. Periods are therefore withdrawn
before they end:

| Period | Local span | Withdrawn when this much is left |
|---|---|---:|
| Morning | 06:00–12:00 | 90 minutes |
| Midday | 12:00–14:00 | 60 minutes |
| Afternoon | 14:00–18:00 | 90 minutes |
| Evening | 18:00–local midnight | 90 minutes |

At exactly the cutoff the period is closed. Before it starts it is open. NOW
never closes.

The remaining time is measured to the **local** end in the reader's own
resolved IANA zone, resolved once when the ritual screen opens and never from
the host machine's clock — `period_availability_test.dart` asserts that one UTC
instant reads as open in Auckland and passed in Los Angeles. Evening ends at
the next local midnight rather than at "24:00", so a 23-, 25- or 23.5-hour day
is exactly as long as it really was; the tests pin all three against
America/New_York and Australia/Lord_Howe.

A closed period is labelled **"Too little time"**, never "Passed", while it is
still running. If the chosen period closes while the screen is open, or while
the app is in the background, the selection drops to NOW with a notice naming
the period — it is never silently swapped for a different named period. The
Reveal tap revalidates against its own instant, so a stale chip cannot produce
a reading: `period_selection_test.dart` covers the timer crossing a cutoff, a
return from the background, and a tap on a selection that expired between the
last paint and the tap, asserting in each case that the repository was never
called and no context was captured.

Boundary coverage is a minute before, exactly at, and a minute after each of
the four cutoffs, plus each period's end, plus a period that has not started.

An unresolvable timezone leaves every period offered. Muting a period on a
clock the app cannot read would be worse than offering it, and the engine still
rejects the zone at Reveal with a message.

### Commands executed on 2026-09-30

| Command | Result |
|---|---|
| `node --test test/*.test.js` | **191 passed, 0 failed** |
| `node scripts/mobile-fixtures.mjs --check` | `All 16 engine fixtures match current engine output.` |
| `node scripts/port/gen_edge_readings.mjs` | 16 edge scenarios regenerated |
| `node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930` | only `T` moved; held-out saturation 0% on every signal |
| `flutter analyze` | **No issues found** |
| `flutter test` | 795 passed, 9 failed — every failure in code this work did not touch; see below |

Node–Dart parity holds at v9.3: all 16 standard fixtures and all 16 edge
readings reproduce byte for byte in the Dart port, `readingKey` included.

### The nine failing Flutter tests are not from this work

At the time of this run another agent was editing the same working tree. Its
commit `76d737c` ("Switch primary app typography to Montserrat and refine home
page layout") removed `homeEyebrow` from every locale and replaced the
`todaySignals` label, but left three test files asserting the old copy:

- `font_coverage_test.dart` (7) — loads fonts by family name and has no entry
  for Montserrat, so the coverage set is null.
- `category_flow_test.dart` (1) — asserts the removed `homeEyebrow` copy.
- `home_signals_test.dart` (1) — asserts the replaced "Daily energy" label.

None of them touches the engine, the guidance or the period selector. Every
test this work added or changed passes.

### Not verified

- **No physical Android device or emulator.** The period cutoff, its two
  disabled states and the notice are verified by widget tests only.
- Predictive validity. None claimed, none tested.
- The rewritten guidance headlines in seven languages are Claude's drafts.

## v9.2 — fixing what the v9.1 review found — 2026-09-30

Engine **4.1.0-mvp** / ruleset
**`civil-midnight-chinese-calendar-symbolic-v9.2-experimental`**, scales
`v9.2-cohort-2026-09-30`.

A review of the v9.1 implementation found four defects and one imbalance. This
section records what changed and what it did to the numbers. Everything below
is behaviour of the software; none of it is evidence that a percentage predicts
anything about a real decision.

### 1. The timing signal could not see inside a period

`T` compared the anchor only against the **periods** that had not started yet.
For an evening reading nothing starts after 18:00, so `T` was exactly zero —
and every candidate window of that reading reused it.

`T` now compares against the rest of the selected period, hour by hour, and
then against the periods still ahead. NOW keeps the old comparison set: it is a
single instant, not a span, so there is no "rest of NOW". The median absolute
raw value of `T` across the calibration cohort rose from **0.011 to 0.089**,
and its held-out median `|tanh|` from **0.0395 to 0.1662** — it now carries
information where it used to carry none.

### 2. A window reused the headline's cross-day signals

Each candidate window is now scored from scratch at its own instant: every
signal the mode mixes is recomputed there, `T` included. The fortnight contrast
is deliberately *not* applied, because a fifteen-minute slot has no fortnight
of its own.

So a window's number means: **this mode's own score for that slot, on the same
display curve as the headline, before the headline's comparison against the
reader's own fortnight.** Windows are ranked by it, ties broken by the earlier
slot.

`test/scoring.test.js` and `test/local_engine/scoring_test.dart` both assert
that ACT / WAIT and YES / NO rank the *same* candidate slots in a *different*
order. YES / NO reads no timing at all, so that difference is the timing signal
moving the ranking — which it could not do before.

### 3. The Node score cache ignored the requested signal set

Its key omitted `needed`, so on one calculator a `probeAllSignals` call after a
normal reading returned only the normal reading's three signals, and — not
reported, but just as real — a normal reading after a probe returned all nine.
The displayed percentages were never affected, because a mode score only reads
the signals its own mixture names, but the reported `scoring.signals` block was
wrong in both directions.

The key now carries the signal set, matching Dart. It also carries the period
again, which it must, because `T` now depends on it. Regression tests cover
both call orders in both engines and check that the reading itself is identical
whichever came first.

### 4. LEFT / RIGHT read nothing about the person

Under v9.1 it was `Y` alone. Two readers with the same date and hour branch got
the same polarity, and it was the only mode that consulted no personal chart.
It is now `.70Y + .20P + .10L`: the polarity convention still decides it.

### 5. The percentage scale meant different things per mode

The headline imbalance: LEFT / RIGHT reached 80%+ on 24.6% of readings while
YES / NO never reached it at all.

The cause is structural, not a tuning accident. A weighted average of several
roughly independent signals is narrower than any one of them — with weights
summing to one, the spread shrinks by `sqrt(sum of w squared)`. LEFT / RIGHT
was one signal at weight 1.0; YES / NO was three signals whose spread was
therefore about 40% narrower before anything was even calculated.

Each mixture is now divided by its own `sqrt(sum of w squared)` (`MODE_GAIN`).
That constant comes from the weights and nothing else — no cohort, no fitting,
no per-user value — and is strictly positive, so it cannot change which side a
mode names, only how far from the middle it reads.

**The cost, stated plainly:** a mixture that averages away more of its evidence
is no longer shown as correspondingly less certain, and the overall mean
winning percentage rose from 64.5 to 67.0. Equalising the instrument makes
"80%" mean the same thing across modes; it does not make any mode better
informed.

### Held-out simulation, v9.1 against v9.2

`dart run tool/simulate_v91.dart --profiles 210 --days 28` from `mobile_app`:
the same 41,160 readings — 210 profiles that contributed nothing to either
calibration, seven modes, 28 consecutive local dates, 20 timezones, seven
categories, no failures.

Winners at 80%+, by mode:

| Mode | v8 | v9.1 | v9.2 |
|---|---:|---:|---:|
| YES / NO | 0.0% | 0.0% | 2.2% |
| ACT / WAIT | 0.0% | 0.0% | 5.1% |
| ADVANCE / RETREAT | 0.0% | 0.1% | 3.1% |
| STAY / GO | 0.0% | 0.5% | 4.8% |
| KEEP / LET GO | 0.0% | 0.5% | 4.6% |
| COMMIT / WITHDRAW | 0.0% | 0.0% | 0.0% |
| LEFT / RIGHT | 0.0% | 24.6% | 19.5% |

Full v9.2 distribution:

| Mode | 50-54.9 | 55-59.9 | 60-79.9 | 80+ | adjacent exact repeats | 7-day same direction | mean |
|---|---:|---:|---:|---:|---:|---:|---:|
| YES / NO | 5.7% | 15.4% | 76.7% | 2.2% | 0.1% | 17.5% | 66.2 |
| ACT / WAIT | 5.0% | 14.1% | 75.7% | 5.1% | 0.3% | 3.8% | 67.1 |
| ADVANCE / RETREAT | 6.5% | 14.8% | 75.6% | 3.1% | 0.2% | 0.5% | 66.3 |
| STAY / GO | 5.5% | 14.3% | 75.4% | 4.8% | 0.1% | 1.8% | 67.1 |
| KEEP / LET GO | 5.8% | 14.5% | 75.1% | 4.6% | 0.2% | 4.8% | 66.9 |
| COMMIT / WITHDRAW | 5.4% | 16.9% | 77.7% | 0.0% | 2.0% | 88.4% | 64.6 |
| LEFT / RIGHT | 3.0% | 8.1% | 69.4% | 19.5% | 0.1% | 14.8% | 71.1 |
| **all** | **5.3%** | **14.0%** | **75.1%** | **5.6%** | **0.4%** | **18.8%** | **67.0** |

Overall, winners in 50–59.9%: v8 98.5% → v9.1 27.1% → v9.2 19.3%.
Winners at 80%+: v8 0.0% → v9.1 5.6% (almost all of it one mode) → v9.2 5.6%
(spread across six).

Repeat behaviour barely moved: adjacent exact repeats stayed at 0.4% overall,
and LEFT / RIGHT's seven-day same-direction rate fell from 20.5% to 14.8%
because the personal share breaks up the parity alternation. Birth-hour
coverage is unchanged — 0.910 known against 0.678 unknown.

### The two imbalances that remain

Reported, not tuned away.

1. **LEFT / RIGHT is still about four times more likely to reach 80%+ than any
   other mode** (19.5% against 2.2–5.1%), and it is the only mode with almost
   nothing in the 50–54.9 band. `Y` still carries half its weight on three
   terms that are each exactly +1 or -1, which gives it a fatter tail than a
   continuous signal has: across the held-out cohort its p95/p75 ratio of
   absolute raw value is 2.3, against 1.5–1.6 for every other signal. The
   fortnight contrast then amplifies it, because a parity term genuinely does
   alternate against its own fortnight. Flattening this further would mean
   changing what `Y` measures, not how it is scaled.
2. **COMMIT / WITHDRAW never reaches 80%+ at all, and holds one direction
   through 88.4% of seven-day windows.** `H` is a median over an eight-day
   window that moves one day at a time, so it barely differs from its own
   fortnight and the contrast term contributes almost nothing. That is the
   durability the mode is for; the number simply records how much of it the
   formula produces.

**v9.2 stays experimental.**

### Commands executed on 2026-09-30

Runtime: Node **v24.19.0**, Dart **3.13.4**, Flutter stable, Windows 11.

| Command | Result |
|---|---|
| `node --test test/*.test.js` | **185 passed, 0 failed** (exit 0) |
| `node scripts/mobile-fixtures.mjs --check` | `All 16 engine fixtures match current engine output.` |
| `node scripts/port/gen_edge_readings.mjs` | 16 edge scenarios regenerated |
| `node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930` | only `T` moved; held-out saturation 0% on every signal |
| `flutter analyze` | **No issues found** |
| `flutter test` | **754 passed, 0 failed** |
| `dart run tool/simulate_v91.dart --profiles 210 --days 28` | 41,160 readings, 0 failures |

Node–Dart parity is re-established at v9.2: all 16 standard fixtures and all 16
edge readings reproduce byte for byte in the Dart port, `readingKey` included.

### Result screen

The day's own signals are back on the result, compactly — both colours, the
lucky number and the energy label, as three caption-and-value rows — with
Action Guidance below them. `localization_layout_test.dart` asserts both are
present and fit at 360dp across 1.0, 1.3 and 1.5 text scale in all seven
languages, and `widget_test.dart` asserts the same at 360x640, 390x844,
412x915 and 800x1280. Home is untouched.

### Result guidance

The guidance was keyed on life-area category and polarity, so every mode said
the same thing, and writing per category had produced lines that told a reader
to leave a relationship. It is now keyed on the **decision mode and which side
the reading named**, and on nothing else. No line names money, work, a partner
or any third person, and none tells the reader to start, end, buy, sell or
leave anything. `test/action_guidance_test.dart` checks a per-language list of
prohibited terms across every mode and side, and that no two modes share a
headline. The copy is Claude-drafted and is flagged for editorial review in
`handoff/localization/CLAUDE_DRAFT_RESULT_GUIDANCE.md`.

Dropped with it: the journey-tenure progression that varied the wording over
the first 30 days, and the daily rotation between three variants. Both selected
between texts that no longer exist. Noted here because neither was asked to go.

### Not verified

- **No physical Android device or emulator was available.** Nothing in this
  release has been seen on a screen; the Result layout is verified by widget
  tests at those sizes and scales, which is not the same thing.
- Predictive validity. None claimed, none tested.
- The result-guidance copy and the ADVANCE / RETREAT words in seven languages
  are Claude's drafts, not the editorial owner's.

## Experimental v9.1 symbolic scoring — 2026-09-30

Engine **4.0.0-mvp** / ruleset
**`civil-midnight-chinese-calendar-symbolic-v9.1-experimental`**.

v9.1 replaces how a decision is scored and nothing else. Birth-data parsing,
timezone resolution, the calendar, natal BaZi, Zi Wei, the Western and Vedic
charts, the daily colours and the daily energy label are untouched, and
`test/foundations.test.js` proves it: the natal charts and the whole daily
brief for eight profiles across four timezones are compared field by field
against a capture taken from the engine as it stood *before* this change.

Instead of projecting one fused `action`/`change` pair onto seven fixed lines,
the engine extracts nine named signals — `P C L T M R G H Y` — several of which
read other local dates, and gives each mode its own mixture of them. Each
signal is normalized with `tanh(raw / scale)` against a fixed, versioned scale
(`SCALE_VERSION = v9.1-cohort-2026-09-30`) measured once, offline, by
`scripts/calibrate-v91.mjs`. Nothing learns or adapts at runtime.

### Decision-mode contract correction

`forward_backward` is retired and replaced by `commit_withdraw`, driven by a
seven-day durability horizon. `advance_retreat` remains its own mode and is now
driven by three-day momentum.

The app had been showing the COMMIT / WITHDRAW words under the ADVANCE /
RETREAT mode in all seven languages. That copy moved to `choiceCommit` /
`choiceWithdraw` and ADVANCE / RETREAT received words of its own.

`calculate` refuses `forward_backward` with
`LEGACY_DECISION_MODE:forward_backward` (HTTP 422), and
`mobile_app/test/fixtures/legacy_forward_backward_reading.json` is a real v8
reading kept verbatim so the app can prove it still parses and renders one. A
saved FORWARD/BACKWARD reading is never relabelled COMMIT: its percentage was
never calculated for that question.

### Calibration

`node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930`: 374 readings
from 120 synthetic profiles across seven categories, four periods and twenty
timezones, roughly a third with no birth hour. Each scale is four times the
75th percentile of that signal's absolute raw value. A disjoint held-out cohort
(60 profiles, 199 readings) showed **0% saturation** on every signal — none had
lost the ability to tell two days apart — with median `|tanh|` between 0.04 and
0.22.

### Held-out simulation

`dart run tool/simulate_v91.dart --profiles 210 --days 28` from `mobile_app`:
**41,160 scored readings** — 210 profiles that contributed nothing to the
calibration, seven modes, 28 consecutive local dates, twenty timezones, seven
categories, no failures. Run in Dart because the two engines produce identical
readings and the Node reference is roughly 300x slower (see Performance below).

The same run also recovers what ruleset v8 would have displayed, exactly, from
each reading's own unchanged fused axes:

| Winning percentage | v8 | v9.1 |
|---|---:|---:|
| 50.0-54.9 | 59.5% | 7.2% |
| 55.0-59.9 | 39.0% | 19.9% |
| 60.0-79.9 | 1.5% | 69.2% |
| 80.0+ | 0.0% | 3.7% |
| mean winning percentage | 54.5 | 64.5 |

By mode, under v9.1:

| Mode | 50-54.9 | 55-59.9 | 60-79.9 | 80+ | adjacent exact repeats | 7-day same direction | mean |
|---|---:|---:|---:|---:|---:|---:|---:|
| YES / NO | 9.9% | 24.5% | 65.6% | 0.0% | 0.2% | 17.5% | 62.3 |
| ACT / WAIT | 9.3% | 24.2% | 66.4% | 0.0% | 0.2% | 3.2% | 62.6 |
| ADVANCE / RETREAT | 9.4% | 21.9% | 68.6% | 0.1% | 0.2% | 0.5% | 63.1 |
| STAY / GO | 7.4% | 19.3% | 72.7% | 0.5% | 0.2% | 1.8% | 64.5 |
| KEEP / LET GO | 7.7% | 20.4% | 71.4% | 0.5% | 0.2% | 4.8% | 64.2 |
| COMMIT / WITHDRAW | 6.7% | 22.1% | 71.2% | 0.0% | 2.0% | 88.4% | 63.0 |
| LEFT / RIGHT | 0.0% | 6.8% | 68.5% | 24.6% | 0.0% | 20.5% | 71.7 |

Category spread is narrow: every category sits between 5.6% and 8.1% in the
50-54.9 band and between 63.9 and 64.9 mean, with `other` tracking `general` as
the honest fallback it is meant to be.

Birth-hour coverage behaved as required: mean data coverage **0.910** with a
known hour against **0.678** without one. Normalization did not turn a missing
chart into confidence.

### Weaknesses found, and not tuned away

Reported rather than coefficient-fixed, because adjusting the formulas to make
the distribution look better is exactly what this work is supposed to avoid.

1. **LEFT / RIGHT is far more extreme than every other mode.** `Y` puts 0.50 of
   its weight on three parity terms that are each exactly +1 or -1, so the raw
   signal is coarse and close to bimodal. The result is 24.6% of readings at
   80%+, a 71.7 mean, and nothing at all below 55%. Two thirds of every 80%+
   result in the whole simulation comes from this one mode. It is doing what
   the specification says, and what it says produces a blunt instrument.
2. **COMMIT / WITHDRAW is very sticky.** 88.4% of seven-day windows named the
   same side throughout, and its adjacent exact repeats (2.0%) are ten times
   any other mode's. This follows from `H` being medians over an eight-day
   window that shifts one day at a time. Durability was the intent; this is how
   much of it the formula produces.
3. **ADVANCE / RETREAT barely persists at all** — 0.5% of seven-day windows
   held one direction — because `M` is a three-day difference. Neither extreme
   was chosen; both fall out of the specified signals.
4. The 50-59.9 band is still 27.1% overall. A large improvement on v8's 98.5%,
   but not near zero, and it should not be driven to zero: a genuinely balanced
   day ought to read as one.

**v9.1 stays experimental.** Nothing here establishes that a percentage
predicts anything about a real decision. It establishes that the software is
deterministic, reproducible from a saved snapshot, and that its modes are no
longer near-copies of one another.

### Performance

`node --expose-gc scripts/bench-v91.mjs` and `dart run tool/bench_v91.dart`:
same profiles, same instant, a fresh calculator per measurement.

| Profile | Dart (ships to Android) | Node reference |
|---|---:|---:|
| known hour + convention | 6-57 ms | 373-999 ms |
| known hour, unspecified | 5-22 ms | 723-1908 ms |
| unknown hour + convention | 9-32 ms | 4295-11266 ms |
| unknown hour, unspecified | 15-37 ms | 8575-22700 ms |

The gap is entirely the Zi Wei provider: `chart.horoscope()` from `iztro` costs
about 15 ms per chart-date-hour and accounts for 95% of a Node reading, while
the Dart port computes the same values natively. An unknown birth hour
multiplies the chart count by twelve and an unspecified convention by
twenty-four, which is why the Node numbers explode and the Dart ones do not.

Two changes were made for this: `scoreChart` is memoized per chart, date, hour
and category (pure memoization — same key, same value), and a reading computes
only the cross-day anchors the chosen mode's signals actually need. Without the
second, the worst Node case was 24 s.

The Flutter app already runs the engine on a background isolate
(`test/local_engine/offline_guarantees_test.dart`) and the ritual screen lasts
4.2-5.2 s, so a 37 ms worst case leaves no room for jank. **Not measured on a
physical Android device** — these are desktop numbers.

### Commands executed on 2026-09-30

Runtime: Node **v24.19.0**, Dart **3.13.4**, Flutter stable, Windows 11.

| Command | Result |
|---|---|
| `node --test test/*.test.js` | **181 passed, 0 failed** (exit 0) |
| `node scripts/mobile-fixtures.mjs --check` | `All 16 engine fixtures match current engine output.` (exit 0) |
| `node scripts/port/gen_edge_readings.mjs` | 16 edge scenarios regenerated |
| `node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930` | scales above; held-out cohort 0% saturation |
| `node --expose-gc scripts/bench-v91.mjs` | table above |
| `flutter analyze` | **No issues found** |
| `flutter test` | **748 passed, 0 failed** |
| `dart run tool/simulate_v91.dart --profiles 210 --days 28` | 41,160 readings, 0 failures, 80 s |
| `dart run tool/bench_v91.dart` | table above |
| `flutter build apk --debug` | `build/app/outputs/flutter-apk/app-debug.apk` |

The Dart port reproduced all 16 standard fixtures and all 16 edge readings
byte for byte, including `readingKey`, which is a SHA-256 over the profile, the
ruleset, the provider versions and the evaluated segments. That is what
establishes the two engines are equivalent rather than merely similar.

`dart:math` has no `tanh`, so the Dart port implements it (`jsTanh` in
`core/scoring.dart`) with an `expm1` series near zero and the exponential form
elsewhere. Agreement is checked directly against known values and, more
importantly, through the whole-reading golden parity above.

### Not verified

- **No physical Android device or emulator was available.** Nothing in this
  release has been seen on a screen, and the performance figures are desktop
  measurements.
- Predictive validity. There is none claimed and none tested.
- The ADVANCE / RETREAT words and one loading line in seven languages were
  drafted by Claude, not by the editorial owner; see
  `handoff/localization/CLAUDE_DRAFT_DECISION_MODES.md`. Vietnamese renders the
  new ADVANCE / RETREAT pair with the same two words as the retired
  FORWARD / BACKWARD pair, which is flagged there.

## Mobile fixture generation run — 2026-09-21

Runtime: Node **v24.19.0** on Windows, engine `3.1.0-mvp`, ruleset
`civil-midnight-chinese-calendar-symbolic-v4`.

| Command | Result |
|---|---|
| `node --test test/*.test.js` | **47 passed, 0 failed** (exit 0) |
| `node scripts/mobile-fixtures.mjs --write` | `Wrote 10 fixtures` (exit 0) |
| `node scripts/mobile-fixtures.mjs --check` | `All 10 engine fixtures match current engine output.` (**exit 0**) |

What this establishes:

- The ten engine-reproducible fixtures in `mobile_app/test/fixtures/` are now **real
  engine golden output**, written verbatim by the engine (including `segments` and the
  emitted `tzdb` 2026d), not hand-authored numbers.
- `--check` re-ran every scenario and compared it to the committed file, and validated
  each fixture's projection with the engine's own `MODES` / `percent` / `scoreForMode`,
  so `modeScore`, `axisScores.selected`, the percentage split and the winner are
  consistent with the shipped formulas rather than with a re-implementation.
- `mobile_app/test/fixtures/synthetic_balanced.json` and `synthetic_insufficient_data.json`
  are **not** generated and remain clearly marked parser-only synthetic fixtures; `--check`
  still validates their projections.
- No calculation formula, module weight or decision-mode projection was modified to reach
  these results. One Flutter test assumption was corrected instead (it had assumed two
  fixtures shared axis scores, which is only true for hand-built data).

Downstream on the same day: `flutter analyze` clean, `flutter test` 74/74,
`dart format --set-exit-if-changed lib/data test/data` exit 0.

## Local API run — 2026-09-21

Runtime: Node **v24.19.0** on Windows. `src/server.js` adds a local HTTP API around
the existing engine; it introduces no dependency and does not touch any calculation
path.

| Command | Result |
|---|---|
| `node --test test/server.test.js` | **21 passed, 0 failed** (exit 0) |
| `node --test test/*.test.js` | **68 passed, 0 failed** (exit 0) |
| `node scripts/mobile-fixtures.mjs --check` | exit 0, fixtures unchanged |

The **47** recorded elsewhere in this file is the engine-only suite, which is still
47 tests and still passes; the full-glob command now also picks up the 21 API tests,
hence 68. The API tests cover route/method/content-type handling, the 64 KiB body
limit, `diagnostics: true` rejection, deterministic `readingKey` across repeated
requests, and an assertion that no error response contains birth data, coordinates,
`inputSnapshot`, `readingKey` or a stack trace.

Two hardening findings were closed on the same day and are covered by tests:

- **Loopback binding is enforced, not merely defaulted.** `startApiServer` rejects
  every host except `127.0.0.1` (`0.0.0.0`, `::`, `::1`, `localhost`, LAN addresses,
  empty and null) *before* `createServer`/`listen`, so no non-loopback listener can
  exist; the test asserts the sentinel `HOST_MUST_BE_LOOPBACK` rather than an OS
  bind error, which is what proves the short-circuit. A CLI boot was also checked
  with `netstat`: one LISTENING socket, on `127.0.0.1` only.
- **Oversized bodies always get JSON 413.** The server no longer destroys the socket
  above an internal threshold. It stops buffering at 64 KiB, discards what it held,
  drains the rest and answers 413 with `no-store` and `nosniff`. Verified at 65 KiB,
  512 KiB, 1 MiB and 2 MiB, with a valid reading served after each.

Not established here: this is a loopback-only development server with no TLS, auth,
rate limiting, request timeouts or deployment hardening, and none of that has been
tested. Draining an oversized upload costs time on an abusive client — a request
timeout is the correct control and is deliberately deferred.

## Category-aware fusion — 2026-09-22

Engine bumped to **3.2.0-mvp**, ruleset **civil-midnight-chinese-calendar-symbolic-v5**,
because the fusion rules changed: `category` now selects module weights, Zi Wei
target palaces and the Western body-emphasis profile.

| Command | Result |
|---|---|
| `node --test test/category.test.js` | **19 passed, 0 failed** |
| `node --test test/*.test.js` | **87 passed, 0 failed** |
| `node scripts/mobile-fixtures.mjs --write` | 16 fixtures written |
| `node scripts/mobile-fixtures.mjs --check` | exit 0 |

What this establishes, and what it does not:

- All seven wire categories (`general`, `love`, `career`, `money`, `study`,
  `friends`, `other`) are accepted; anything else raises `INVALID_CATEGORY`, and
  an omitted category still defaults to `general`.
- Category reaches the **calculation**, not just the label: on the reference
  case the Zi Wei axis moves from `+0.0251` (general) to `-0.0219` (love) and
  `+0.0392` (money), and at least four distinct mode scores appear across the
  seven categories.
- `category` is part of the evaluation cache key, `readingKey` and
  `inputSnapshot`. `general` and `other` share the formula by design and produce
  the same score with **different** reading keys; no random noise was added to
  force them apart.
- `N` (numerology), `U` (cosmic) and `T` (almanac) remain category-neutral
  internally, and `B` (BaZi) keeps its verified evidence — category emphasis for
  `B` comes only from the documented fusion weight.
- The seven decision-mode coefficients are asserted unchanged, and the Python
  reference comparison still passes, so `general` behaviour is preserved.
- The category weights, Zi Wei palace targets and Western body profiles are
  **symbolic editorial emphases**. Nothing here establishes predictive validity,
  and no automatic Yong Shen or gender-based spouse/wealth rule was introduced.

## Expanded symbolic daily energy — 2026-09-23

Engine **3.4.0-mvp** / ruleset **v7** retains the duration-weighted full-day
index and coverage gate from v6. The label now uses both fusion axes:
`FOCUSED` when action leads change by at least 0.06 and action is at least
0.04, `FLOWING` for the inverse; otherwise six index bands produce `QUIET`,
`SOFT`, `STEADY`, `LIVELY`, `BRIGHT`, or `RADIANT`. The axis gate avoids
calling a negative score action-led merely because the other axis is even
lower. The rules are editorial symbolic descriptions, not measured mood,
health, or odds. See `outputs/Daily_Energy_Formula_v2.md`.

A calibration sample of 30 local days for each of three synthetic profiles
produced seven of the eight labels: `FOCUSED` 20, `FLOWING` 23, `QUIET` 4,
`SOFT` 6, `STEADY` 15, `LIVELY` 15, `BRIGHT` 7, and `RADIANT` 0. `RADIANT`
remains possible at a higher index but is intentionally rare. There were 14
same-label adjacent pairs among the 87 within-profile day transitions. This
sample tests variety and reachable thresholds; it does not validate the
symbolic interpretation against real-world outcomes.

Checks on 2026-09-23: **91/91 Node tests**, **338/338 Flutter tests**, fixture
check **16/16**, all 16 standard and 16 edge readings matched the Dart port,
Flutter analyzer clean, and the debug Android APK built successfully.

## Daily colours and percentage display — 2026-09-24

Engine **3.5.0-mvp** / ruleset **v8** keeps the established reading scores and
mode projections. Headline percentages now show one decimal using integer
tenths; they remain symbolic alignment scores, not success probabilities.
The daily brief has a lead colour from the local day's stem-specific pair and
a supporting colour from the generating-element family. The 20-colour rule
uses duration-weighted full-day general-module signals and does not infer
traditional Yong Shen or a missing birth hour. The Flutter reader retains
legacy single-colour history snapshots without recalculating them.

Executed on 2026-09-24: `node --test test/*.test.js` **111/111 passed**;
`node scripts/mobile-fixtures.mjs --check` **16/16 matched**;
`flutter analyze --no-pub` **no issues**; `flutter test --no-pub`
**455/455 passed**; `flutter build apk --debug --no-pub` succeeded.
The Flutter tests cover history migration and UI geometry, but no connected
Android device was available for a screenshot review of the updated screens.

## Symbolic daily energy v6 — 2026-09-23

Engine **3.3.0-mvp** / ruleset **v6** adds `dailyBrief.energy`. The full local
day is segmented with the existing calendar and timezone rules, including
23/25-hour DST days. General six-module fusion is averaged by actual segment
duration, then the editorial 65% action / 35% change projection maps to
`SOFT`, `STEADY` or `BRIGHT`. Coverage below 0.2 returns `unavailable`.

The daily label does not change with mode, category, chosen period or Reveal
time within the same local date. It is a symbolic product signal; no physical
energy measurement or predictive accuracy has been established. The Dart
offline port matches 16 generated engine fixtures and 16 edge readings.

Checks on 2026-09-23: **90/90 Node tests**, **338/338 Flutter tests**, fixture
check **16/16**, Flutter analyzer clean. See
`outputs/Daily_Energy_Formula_v1.md` for the exact equation and UI meaning.

## Executed checks

| Check | Result | What it establishes |
|---|---|---|
| Node unit/integration/CLI tests | 47 tests passed | Raw input pipeline, missing data, deterministic snapshots, mode mapping, valid windows, immutable results |
| Original Python tests | 45 tests passed | Earlier v1/v2 reference files still function |
| Calendar stress | 10,000 cases passed | Pillar parity/ranges, global local dates; periodic checks for complete non-overlapping segments |
| End-to-end stress | 1,000 readings passed | Six-module pipeline remains finite and bounded, percentages sum to 100, period states handled |
| Unknown-hour subset | 200 of the 1,000 readings | Missing-hour code paths with 12-chart Zi Wei scenarios |
| Solar-term boundary sweep | 240 transitions passed | Month changes at exact global Jie boundaries across 2016–2035 |
| JS vs original Python | 189 numeric comparisons across 9 chart/time cases passed | Six module scores and normalized no-space fusion match within 1e-8 |
| Host timezone independence | UTC, America/Los_Angeles, Asia/Tokyo passed | Machine timezone does not silently replace the user context |

Stress suite elapsed about 81 seconds on this development environment. This is not
a mobile-device performance benchmark or a promise about server throughput.

## Source checks represented in tests

- HKO lunar conversion examples: six dates in 2024/2025.
- HKO Li Chun 2024: UTC conversion checked within two minutes of the published rounded time.
- HKO new Moon 2025-01-29: geocentric elongation near zero at the published time.
- USNO March equinox 2024: apparent geocentric solar longitude near zero.
- Provider example 2000-08-16 03:00: Four Pillars and Zi Wei life/body palaces.
- BaZi Yun start offsets match provider sect 2 on a no-DST fixture.
- US DST gap/fold; Lord Howe half-hour DST; Nepal/Eucla fractional offsets;
  Samoa skipped date; midnight versus 23:00 Zi; leap lunar month.

HKO and USNO are independent of the application providers. Provider example tests
and Python comparisons are **not** independent validation of all traditional rules.
There has not been a manual expert audit of dozens of complete Bát Tự/Tử Vi charts.

## Explicit exclusions

- No evidence here establishes that the symbolic YES/NO scores predict real-world outcomes.
- Automatic traditional Yong Shen / Xi Shen and all special chart structures are not implemented.
- No native Unity/Android/iOS integration or sensor permission flow has been device-tested.
- Geographical border-buffer checks use 16 samples, not a proof that an entire accuracy circle lies inside one timezone.
- No production load/security deployment test; no server has been deployed.

## Reproduce

From `calculation-engine`:

```sh
node --test test/*.test.js
node scripts/stress.js
node scripts/check-reference.js
node scripts/mobile-fixtures.mjs --check
```

`scripts/mobile-fixtures.mjs` regenerates (`--write`) or verifies (`--check`) the Flutter
DTO fixtures in `mobile_app/test/fixtures/` against live engine output, and validates each
fixture's mode projection with the engine's own `MODES`/`percent`/`scoreForMode`. It was
run on 2026-09-21: `--write` produced 10 fixtures and `--check` exited 0. See
`mobile_app/test/fixtures/README.md` for per-fixture provenance.

From the workspace root:

```sh
python -B -m unittest discover -s outputs -p "test_decision_formula*.py"
```
