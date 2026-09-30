# v9.1 normalization scales

`SCALES` in `src/scoring.js` and `scales` in
`mobile_app/lib/local_engine/core/scoring.dart` hold nine constants, one per
signal. They are not tuning knobs and nothing at runtime may recompute them.

## What they are

Each signal `s` has a scale, and is normalized as `tanh(raw_s / scale_s)`.

    scale_s = 4 x P75(|raw_s|) over the calibration cohort

Four times the upper quartile puts an ordinary day well inside the straight
section of `tanh`, so small differences between days survive, while still
leaving an unusual day somewhere to go. It is a deliberately blunt rule: one
number, from one published statistic, on a cohort anybody can regenerate.

## Reproducing them

From `calculation-engine/`:

```sh
node scripts/calibrate-v91.mjs --profiles 120 --seed 20260930
```

The committed scales came from exactly that command. It prints a constant block
to paste into `src/scoring.js`, then measures a second, disjoint cohort against
the scales it just chose and reports how often each signal saturates.

The Dart copy in `mobile_app/lib/local_engine/core/scoring.dart` must be
identical, digit for digit. The two engines normalizing differently would mean
the same reading showed a different percentage depending on where it was
calculated, which `mobile_app/test/local_engine/golden_reading_parity_test.dart`
exists to catch.

## The cohort

`scripts/cohort.mjs`, seeded. The randomness is offline and decides only which
imaginary profiles get measured; nothing in `src/` imports it, and no random
value ever reaches a reading.

- 120 synthetic profiles, birth years 1940–2010.
- Roughly a third have no birth hour, so unknown-hour coverage is inside the
  calibration rather than beside it.
- 24 birth countries and 20 device timezones, including half-hour and
  quarter-hour offsets, both DST hemispheres, and zones with no DST.
- All seven categories and four periods.
- 374 scored readings in total.

## What is *not* calibrated

`MODE_GAIN` is not. Each mixture is divided by its own
`sqrt(sum of w squared)`, which comes from the weights and nothing else — no
cohort, no fitting, no per-user value. It exists because a weighted average of
several roughly independent signals is narrower than any one of them, which
made a four-signal mode structurally milder than a one-signal mode. It is
strictly positive, so it can never change which side a mode names.

## Why changing them is a release decision

A scale change moves every percentage the app has ever shown. Saved readings
are snapshots and are never recalculated, so the old ones stay as they were —
which means two readings a user compares could have been scored under different
scales. That is acceptable only if the change is deliberate, versioned through
`SCALE_VERSION`, and recorded in `VERIFICATION.md` with the cohort it came
from.

Do not adjust a scale to make a distribution look better. The 2026-09-30
held-out simulation in `VERIFICATION.md` lists the weaknesses these scales
produce — LEFT / RIGHT in particular is coarse — and they are reported rather
than tuned away on purpose.
