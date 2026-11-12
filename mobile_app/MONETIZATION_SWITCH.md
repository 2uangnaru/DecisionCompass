# Temporary iOS free edition — 2026-11-12

Owner decision: **iOS only**, all usable features free. Android keeps the existing Ads/Plus/quota behavior. This supersedes the monetization defaults in the earlier iOS preparation notes.

`MonetizationPolicy.enabledFor` defaults to false on iOS and true on Android. `IOS_MONETIZATION_ENABLED` defaults to false in all build modes, including demo. It is a build-time switch, not a remote unlock.

When disabled:

- No AdMob service or Plus controller/store is constructed by startup; no consent/ATT prompt, purchase query, restore, preload or ad display is initiated by the monetization flow.
- The dependency boundary supplies an unmetered, non-persisting quota, no-op ads, no guidance gate and no Plus controller. This also protects routes reopened from History or passed an old exhausted quota/locked guidance store.
- All decision pairs, categories, valid periods and result guidance are available. No daily reading limit, monetization cooldown or reward is needed. The real time-period cutoffs, responsible-use gate and profile edit cooldowns remain intact.
- Home hides the VIP badge and reading/purchase tray. Its existing daily auspicious-hour calculation is shown as a neutral localized row for everyone. The daily energy/color/number card, header settings/profile and main navigation stay.
- Reveal hides the quota badge, watch-ad/upsell card and banner slot. Result hides purchase/energy upsells and shows full guidance. No empty banner space or fake VIP/earned credit is substituted.
- Existing purchase proofs, quota/cooldown/bonus counters, guidance locks, profile and history are not erased or rewritten by the free edition. A result still saves normally; old snapshots are not recalculated.
- Optional consent-based usage analytics is separate and retains its existing behavior. Disabling ads is not a claim that all optional analytics collection is disabled.

The release template sets `IOS_MONETIZATION_ENABLED=false`, `IOS_ADS_ENABLED=false`, `IOS_TRACKING_ENABLED=false`. No Plus product ID or IAP agreements are needed for this free edition. Real Apple signing/team and public privacy/terms/support pages remain necessary for distribution.

To re-enable in a later reviewed build: set `IOS_MONETIZATION_ENABLED=true`, configure the genuine non-consumable product, and separately enable/configure genuine iOS ads if desired. Complete the StoreKit/UMP/ATT/native QA in `IOS_RELEASE.md`. Enabling this switch restores the original persisted state and monetization rules; it does not refill quota or grant Plus. Do not enable it with placeholder products/IDs.

## Follow-up verification

- `flutter analyze --no-pub`: no issues (`build/ios-free-analyze.log`).
- New free-edition suite: **14 passed**, including the iOS/Android switch, real persisted exhausted quota/active entitlement preservation, conflicting release configuration, Home in all eight languages at 360×740 and 1.5 text scale, free Reveal→Result/history save, historical guidance and the responsible-use gate (`build/ios-free-visual-tests.log`).
- Existing billing/iOS preparation, Android monetization gates, reading flow, periods, profile editing/policy, safety scroll gate and history flow: **234 passed**, 0 failed (`build/ios-free-regression-tests.log`).
- Reviewed Flutter-rendered Home (Vietnamese/Hindi), Reveal and Result previews with bundled fonts and Material icons. All eight Home previews plus Reveal/Result were exported under ignored `build/ios-free-review/`. These are widget renders on Windows, **not native iPhone/iPad QA**.
- `bash -n` passes for the updated build/preflight scripts; `git diff --check` has no whitespace errors.
- Engine/formulas, Android native files and profile edit policy were not modified for this switch. The earlier 1,693-test full-suite record is historical; the current follow-up is the **248-test** set above, not a new claim of a full-suite rerun.
- Native signing/build/StoreKit/SDK behavior on Apple hardware remains unverified on this Windows host. This work belongs to `codex/ios`; publication of this branch does not merge it into `main` or publish an App Store build.
