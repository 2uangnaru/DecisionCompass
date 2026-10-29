# AstraCue Plus billing and entitlement

Updated 2026-10-29. Android-first. App-side logic only: no Play Console
product, no verifier server and no real purchase has been tested. Nothing
here is production sign-off.

## Product rules (implemented)

- Plus is ONE non-consumable, one-time product. It is never consumed.
- Active Plus: 6 daily credits instead of 3 (shared, not 3 + 6), no
  reading-energy cooldown, every mode / category / still-available period
  unlocked, Action Guidance unlocked, no banner / interstitial / rewarded.
- Usage is never rewritten: 2 used then upgrade leaves 4; restore, restart
  or refresh never refill; revocation keeps usage (5 used leaves 0 free).
- Midnight resets daily usage; bonus credits survive and are still spent
  first. With everything spent, the existing exhausted state is shown and no
  ad is offered to a Plus owner.
- A purchase never Reveals, calculates or spends a credit, and never changes
  the current mode / category / period.
- Profile-edit cooldowns, elapsed periods and responsible-use rules are
  untouched. No engine formula, percentage or saved snapshot changed.

## Architecture

| File | Role |
| --- | --- |
| `lib/billing/plus_billing.dart` | Config (`PLUS_PRODUCT_ID`), `PlusStore` boundary + `InAppPurchasePlusStore` (official `in_app_purchase` 3.3.1, Android 0.5.5 / Play Billing 9.1), `PlusPurchaseVerifier` contract + `UnconfiguredPlusVerifier` (the production default) |
| `lib/billing/plus_entitlement.dart` | `PlusEntitlementController`: the single source of truth (`PlusAccess.isActive`), lifecycle, persistence (`plus_entitlement_v1`), restore, reconciliation |
| `lib/data/reading_quota_controller.dart` | Limit 3/6 and cooldown read the entitlement; the serialized commit enforces it independently of any UI |
| `lib/services/ad_runtime.dart` | `setAdFree` (drops cached/in-flight ads, no loads, banners lose permission), `claimFullscreen` / `releaseFullscreen` for checkout |
| Pages | Gates read `dependencies.plusActive`; the Plus sheet receives the controller |

### Grant policy

- Only a purchase whose proof the verifier answers `valid` grants. Buy taps,
  launched checkout, pending, errors, timeouts, receipts without
  verification and any UI action grant nothing.
- `invalid` / `unavailable` purchases are NOT acknowledged, so Play
  redelivers them (and refunds unacknowledged ones after its window).
- Valid purchases are acknowledged via `completePurchase`; duplicates and
  late callbacks verify and grant once.
- Restart recovery: on start, without an active entitlement, the app runs a
  silent owned-purchases query (no restore result is reported).
- Offline / cache: a previously VERIFIED entitlement stays active across
  offline starts and failed or incomplete queries. Only a verifier answer of
  `revoked` removes it. The record is local SharedPreferences and is not
  tamper-proof; a server-side entitlement would be needed for that.
- No fake success exists in `lib/`. Tests inject fake stores/verifiers.

### Verifier contract (owner must provide)

No verifier server exists, and no HTTP client ships: the production graph
must stay free of HTTP packages (`test/local_engine/offline_guarantees_test.dart`),
so adding a network verifier is a deliberate, reviewed change to that test.
Suggested contract for the owner's server adapter: `POST` (https) with JSON
`{productId, purchaseId, serverVerificationData, source}`; respond 200
`{"status": "valid" | "invalid" | "revoked"}`. The server must check the
Play purchase token with the Google Play Developer API (purchase state,
product id, package name, refund/void status). Anything else is
`unavailable`. Without a configured verifier, checkout is blocked
(`verifierNotConfigured`) and nothing can activate.

Build: `flutter build appbundle --dart-define=PLUS_PRODUCT_ID=<id>`; then
replace `plusVerifierFor` in `plus_billing.dart` with the real adapter.

## Demo billing (owner preview, no accounts)

Owner decision 2026-10-29: the paywall's prices are fixed preview copy
($4.99 with a struck-through reference price and -60% badge, and the
per-language equivalents). Until store accounts exist, a demo flow lets the
owner try Plus on a device:

```powershell
flutter build apk --debug --dart-define=PLUS_DEMO_BILLING=true
```

- `lib/billing/plus_demo.dart`: `DemoPlusStore` "purchases" after 0.6 s with
  a proof whose source is `astracue_demo`; `DemoPlusVerifier` accepts only
  that source. The grant still goes through the normal verified path, so
  quota, ads and gates behave exactly as for a real purchase.
- Enabled only when `kDebugMode` AND the define are both true; a release
  build can never use it. The paywall keeps its preview prices.
- A saved demo entitlement is ignored by any non-demo build
  (`acceptDemoProofs`), so it cannot leak into a store build.
- Restore finds an earlier demo purchase on the same install. Clearing app
  data removes both the entitlement and the demo purchase.

## Store build: checkout BLOCKED on unsupported sale claims

The approved CTA shows a struck-through reference price (e.g. `$11.99`) and a
`-60% OFF` badge. Those values are preview copy per language. The official
plugin exposes only `price`, `rawPrice` and `currencyCode` for one-time
products: no original price or discount. The app does not fabricate one, so
`requireSupportedSaleClaims` keeps checkout blocked
(`PlusBlockReason.unsupportedSaleClaims`). When the store answers, the sale
price is replaced by the store's own formatted price; the reference price
stays as preview copy because nothing genuine can replace it.

Owner decision needed: approve a CTA presentation without a reference price
and discount (or one backed by a real store offer), then set
`requireSupportedSaleClaims: false` in `main.dart`.

## States without an approved presentation (logic done, UI pending approval)

Exposed on `PlusEntitlementController` (`checkout`, `lastOutcome`,
`lastRestore`, `checkoutBlockReason` / `lastBlock`), not shown anywhere:

1. Checkout blocked (any `PlusBlockReason`): the CTA tap does nothing and the
   sheet stays open. The old "UI preview is ready" toast was removed because
   it described a mock.
2. Purchasing / pending payment / verifying: no indicator. Pending does not
   block navigation and holds no ad guard.
3. Cancelled / failed / invalid / verification unavailable: no message.
4. Restore result (restored / nothing to restore / unavailable / failed):
   the sheet closes as before; only an activated entitlement is visible.
5. Plus-owned presentation: the existing upsell surfaces (header PLUS badge,
   "6 turns · No Ads" box, sheet) still render for an owner. Credit text now
   reads `x/6`, but the orb row still draws 3 orbs.
6. Ritual with every Plus credit spent: the watch-ad button is hidden and
   the subtitle falls back to the existing `keepChoiceInMind` line; a
   dedicated message needs copy approval.
7. Sheet semantics label (`sheetPrimaryCta`) still contains the preview
   price.

## Verification (2026-10-29, fakes only)

- `test/plus_billing_test.dart` (30): checkout gates, verified-only grant,
  pending/cancel/error/invalid/unavailable/revoked, duplicates, already
  owned, restart recovery, offline survival, revocation, corrupt record,
  3 vs 6 credits, upgrade/revocation usage, midnight + bonus-first, ad-free
  service (cached ads dropped, late loads discarded, no requests/shows,
  checkout guard).
- `test/plus_gates_test.dart` (6): Home/Ritual/Result gates bypassed, a
  purchase mid-Ritual removes the ad button without starting a reading,
  store price binding, blocked sale CTA, Restore wiring.
- `test/flutter_test_config.dart`: every test starts with platform reduced
  motion, which the continuously animated Plus widgets already honour, so
  `pumpAndSettle` can settle. Production animation is unchanged.

These fakes do NOT prove native billing, Play acknowledgement, refunds or
store readiness.

## Required before real purchases

Play Console account and app, the one-time product (`PLUS_PRODUCT_ID`) with
localized prices, a licence-tester / test track build, a deployed verifier
with Play Developer API credentials (never in the app) plus its app adapter, real purchase /
pending / cancel / refund / reinstall-restore QA on a device, and the CTA
decision above. iOS: StoreKit config and App Store Connect product later.
