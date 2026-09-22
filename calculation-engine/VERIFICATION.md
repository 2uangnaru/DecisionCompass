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
