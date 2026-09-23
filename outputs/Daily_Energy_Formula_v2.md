# Daily Energy v2 — eight symbolic tones

Daily Energy describes the general fusion for the user's **whole local day**.
It is a symbolic cue for reflection, not a measure of health, mood, physical
energy, or the chance that a decision will succeed.

The engine divides the local day at its existing calendar, hour-branch and DST
boundaries. For each segment it evaluates the six modules under `general`, then
weights action (`A`), change (`C`), and data coverage by the segment's **actual
elapsed seconds**. The existing index remains:

`index = floor(50 + 40 × clamp(0.65 × A_day + 0.35 × C_day, -1, 1) + 0.5)`

Coverage below 0.2 returns `unavailable` with a null index. Otherwise the
following editorial rules select exactly one label, in order:

| Condition | Label | Meaning within the symbolic model |
|---|---|---|
| `A_day ≥ 0.04` and `A_day − C_day ≥ 0.06` | FOCUSED | Action axis leads |
| `C_day ≥ 0.04` and `C_day − A_day ≥ 0.06` | FLOWING | Change axis leads |
| index < 49 | QUIET | Low projected tone |
| index = 49 | SOFT | Gently low projected tone |
| index 50–51 | STEADY | Near-center projected tone |
| index 52–53 | LIVELY | Gently high projected tone |
| index 54–57 | BRIGHT | Higher projected tone |
| index ≥ 58 | RADIANT | Highest projected tone |

`FOCUSED`, `FLOWING`, and an intensity label can share the same index. They
name different relationships between the two axes rather than changing the
numeric result. The 0.04 and 0.06 margins prevent very small or negative axes
from receiving an axis-led label.

The label is fixed for the same profile, local date and timezone. It does not
depend on the selected decision mode, category, period, or time of the Reveal
tap. The index and coverage remain internal fields, never percentages in the
UI. Old saved snapshots with `SOFT`, `STEADY`, or `BRIGHT` remain readable.

These thresholds are product language choices, not empirical calibration of
real-world outcomes. Engine/ruleset v7 distinguishes new snapshots from v6.
