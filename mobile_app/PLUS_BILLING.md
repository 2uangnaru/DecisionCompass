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
- Valid purchases are acknowledged. On Android the adapter reads the
  `BillingResult` that `InAppPurchaseAndroidPlatform.completePurchase`
  returns (the app-facing API drops it); anything but `ok`, a throw or a
  timeout marks the acknowledgement pending.
- Delivery is idempotent; revalidation is not. Repeated `purchased`
  callbacks deliver and verify once. Every `restored` purchase (explicit
  Restore, startup or resume reconciliation) is verified again, even one
  already granted, so a confirmed `revoked` removes access.
- Offline / cache: a previously VERIFIED entitlement stays active across
  offline starts, verifier throws/timeouts and failed, empty or incomplete
  queries. Only `revoked` for the matching token removes it, restoring the
  free gates and ads without touching usage. The record is local
  SharedPreferences and is not tamper-proof.

### Recovery behaviour (2026-10-29 lifecycle fixes)

- Bounded calls: verification `verifyTimeout` (20 s), each store call
  `storeTimeout` (20 s). A throw or timeout is `unavailable`/failed; a late
  answer is never applied. Updates run on one ordered queue whose jobs
  cannot throw, so a failure never strands checkout in `verifying` or blocks
  later updates; Buy and Restore work again at once.
- Android checkout results: Play errors arrive as `IAPError(code:
  'purchase_error', message: 'BillingResponse.<name>')`, and an empty
  purchase list as `PurchaseDetails(productID: '')`. The adapter normalizes
  them to `PlusStoreError` (no raw text leaves it). An anonymous cancel/error
  settles only the checkout this controller launched; anything else
  anonymous is ignored and never grants. `alreadyOwned` triggers an
  owned-purchases query whose result is verified normally.
- Startup always reconciles owned purchases, even with cached Plus: it
  rechecks the cached proof, picks up purchases completed while the app was
  killed and retries unacknowledged ones (Play lists them with their real
  acknowledgement state). A failed acknowledgement is retried by the next
  start or by a resume at most once per `resumeRetryInterval` (1 min); no
  timer loop. The product is never consumed.
- Store discovery is separate from the one-time subscription: an
  unavailable store or failed/missing product is retried by a resume (same
  spacing), by a Buy tap and by Restore; a failed query keeps the last
  genuine product. Recovery never skips the verifier or sale-claim checks.
- Overlapping startup, resume and Restore share one owned-purchases query
  and one discovery attempt. Nothing mutates entitlement, persistence or ads
  after `dispose`.
- Resume recovery (2026-10-29, after 599f7f4). A resume runs the
  owned-purchases query, at most once per `resumeRetryInterval` and only
  while checkout is idle or pending, when any of these holds:
  - the last reconciliation did not settle: the query threw or timed out,
    the store was unavailable so it could not run (it runs once discovery
    succeeds), the store listed a payment still pending, or the verifier
    could not answer for a purchase not yet granted;
  - an acknowledgement failed (`acknowledgementPending`);
  - a checkout is `pending`. Play sends no callback for a payment that
    completes while the app is away, so the query is how it is found.

  The condition is in memory only. Every start reconciles anyway and
  re-derives it, so an acknowledgement that failed before a restart is
  recovered even when the startup query fails too. Nothing native is
  persisted. A clean query recomputes `acknowledgementPending` from that
  run and clears the condition, after which resumes query nothing.
- A verified purchase found by that query settles a pending checkout
  (`verified`, idle) and is acknowledged once. A payment still pending, an
  empty list or a failed query leaves the checkout pending and grants
  nothing. The verifier being down keeps it ungranted, unacknowledged and
  retryable. Recovery never launches a purchase.
- Android's `restorePurchases` relabels every listed purchase `restored`,
  pending ones included. The adapter maps a `PurchaseStateWrapper.pending`
  purchase back to pending, so it is never verified, granted or
  acknowledged.
- Limitations: an owned purchase Play stops listing (refund) is only
  revoked through the verifier's answer for the cached proof; with no
  verifier it stays active. A pending payment that is canceled leaves the
  checkout `pending` for the rest of the session, because an empty list is
  not proof of cancellation; a restart clears it.
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

- `test/plus_billing_test.dart` (62): recovery R1-R10 (failed ack +
  restart + failed startup query, store down at start, spaced repeated
  failures, cleared retry work, pending payment completed while away,
  still-pending and Android pending-as-restored, empty/failed query while
  pending, verifier down then retry, shared query, disposal), lifecycle
  fixes 1-14 (verifier
  throw/timeout, stale results, realistic Android already-owned / cancel /
  error payloads mapped by the real adapter, BillingResult acknowledgement,
  ack failure + restart / spaced resume recovery, Restore revalidation and
  revocation, store/product recovery, coalescing, disposal), checkout gates, verified-only grant,
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

Each lifecycle fix was mutation-checked: breaking it (no exception handling,
no timeout, anonymous updates dropped, wrong error field, no reconcile when
cached, ack result ignored, restored treated as duplicate, one-shot
discovery, no coalescing, no dispose guards) fails a named test. The
recovery tests fail on the 599f7f4 controller (10 of 12) and catch each
recovery change removed on its own: failed query, store unavailable,
listed pending and unverified purchase not recorded; pending checkout not
eligible or blocked; pending checkout not settled; adapter trusting the
`restored` label; and no retry spacing. R7 and R10 are guards. They pass on
599f7f4, which never ran the query.

These fakes and adapter mappings do NOT prove native billing, Play
acknowledgement, refunds or store readiness; that needs a configured Play
test track.

## Required before real purchases

Play Console account and app, the one-time product (`PLUS_PRODUCT_ID`) with
localized prices, a licence-tester / test track build, a deployed verifier
with Play Developer API credentials (never in the app) plus its app adapter, real purchase /
pending / cancel / refund / reinstall-restore QA on a device, and the CTA
decision above. iOS: StoreKit config and App Store Connect product later.
