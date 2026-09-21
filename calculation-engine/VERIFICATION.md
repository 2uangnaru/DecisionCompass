# Verification record — 2026-09-19

Runtime used: Node.js 24.19.0, Python 3.14.7, Windows. Engine 3.0.0-mvp.
Pinned package versions and tzdb are emitted in every result.

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
```

From the workspace root:

```sh
python -B -m unittest discover -s outputs -p "test_decision_formula*.py"
```
