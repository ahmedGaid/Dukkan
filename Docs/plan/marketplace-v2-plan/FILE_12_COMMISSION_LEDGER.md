# SESSION 12 — Commission Ledger
# Files: lib/domain/config/** (new, platform config), lib/domain/order/entities/order.dart (+model), checkout/order-create path, status-update path, seed_demo_data.dart, firestore.rules

---

## Before You Start

1. Open the checkout flow (search order-create use case / cart bloc submit) — find where `totalMinor` is computed. Confirm whether any delivery fee exists today (likely not → fee = 0 baseline).
2. Re-read the money rules in `core/money.dart` header comments.
3. Open `firestore.rules` — `/config` will be a new match block.

Do not write anything yet.

---

## Task A — `/config/platform` doc

```
/config/platform
  commissionBps: 500                  ← 5% = 500 basis points (integer)
  deliveryFeeMinor: 3000              ← 30 EGP default customer fee (piasters)
  driverDeliveryShareMinor: 2500      ← 25 EGP to driver
```

Platform delivery share = `deliveryFeeMinor - driverDeliveryShareMinor` (derived, not stored in config). Rules: `allow read: if request.auth != null; allow write: if false;` — founder edits via console/seed. Seed script writes the doc. Small `PlatformConfig` entity + repo (`getConfig()`, cached per app session — config reads must not add a round-trip to every checkout; fetch once, refresh on app start).

## Task B — Snapshot fields on Order

Entity/model additions (all optional-with-default so old docs parse; integers only):

```dart
final int subtotalMinor;              // items only; old docs: fall back to totalMinor
final int deliveryFeeMinor;           // default 0
final int commissionBps;              // rate at creation time; default 0
final int commissionMinor;            // computed once; default 0
final int driverDeliveryShareMinor;   // default 0
final int platformDeliveryShareMinor; // default 0
final bool commissionPayable;         // default false
```

## Task C — Compute at creation (round-half-up)

In the order-create path:

```dart
final cfg = await getConfig();
final subtotal = /* existing items sum */;
final commission = (subtotal * cfg.commissionBps + 5000) ~/ 10000; // round-half-up
final total = subtotal + cfg.deliveryFeeMinor;
```

Order doc gets all Task B fields (`commissionPayable: false`). Integer math only — the `+ 5000` before `~/ 10000` is the round-half-up; add a unit test pinning e.g. 500 EGP × 5% = 25 EGP (`50000 * 500 → 2500` piasters) and an odd case that exercises rounding.

**Customer-facing checkout/summary now shows delivery fee + total** (money.dart formatting); Session 2's fee/total block on order details switches from the placeholder to the real fields.

## Task D — Payable flip

In the status-update path (same place as Session 1 history append): transition to `delivered` → also set `commissionPayable: true`. `cancelled`/`rejected` → leave numbers, payable stays false. Rules: extend the allowed-update key set accordingly.

## Task E — Future-rates note (no code)

Add one comment where the rate is resolved: resolution order for later = shop override → campaign → platform default; snapshot pattern already isolates history. Nothing else built now.

---

## Smoke Test

- [ ] Unit tests: rounding cases green.
- [ ] New order on device: doc shows subtotal/fee/commission fields; checkout showed fee + correct total; customer paid total includes 30 EGP fee.
- [ ] Deliver it → `commissionPayable: true`. Cancel another → numbers present, payable false.
- [ ] Change `commissionBps` in console to 700 → NEW order snapshots 700; delivered old order unchanged.
- [ ] Client write to `/config/platform` denied (rules).
- [ ] Old seeded orders parse with defaults; both order lists render. Gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_13_FINANCE_SUMMARY.md
```
