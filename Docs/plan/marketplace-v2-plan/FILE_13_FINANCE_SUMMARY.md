# SESSION 13 — Finance Summary (Founder-Gated)
# Files: lib/presentation/finance/** (new page + bloc), lib/data/finance/** (aggregate datasource), router, firestore.rules, arb files

---

## Before You Start

1. Confirm founder uid to gate on: the doc for `ahmedgaid14@gmail.com` is uid `LPPjx32MJpWlMR3SEksJ7sY2NAF2` (verify in console — do NOT hardcode without checking). Gate = const in one place (`lib/core/` config), clearly commented as v1 stopgap until a real admin role exists.
2. Read Firestore aggregate query docs pattern already used anywhere in the codebase (search `count()` / `aggregate`); if unused so far, this session introduces it.
3. Open `firestore.rules` — owners can currently read only their shop's orders; the founder needs cross-shop read for aggregates.

Do not write anything yet.

---

## Task A — Rules: founder read

Add to `/orders` read rule: `|| request.auth.uid == <founderUid>` (kept literal in rules — rules can't read config docs cheaply; comment it). This is the one place the uid appears besides the app-side const.

## Task B — Aggregate datasource

Six metrics via aggregate queries (no doc downloads):

```dart
final delivered = ordersCol.where('status', isEqualTo: 'delivered');
count:        ordersCol.count()
deliveredCnt: delivered.count()
cancelledCnt: ordersCol.where('status', whereIn: ['cancelled','rejected']).count()
commission:   delivered.aggregate(sum('commissionMinor'))
deliveryRev:  delivered.aggregate(sum('platformDeliveryShareMinor'))
```

Platform revenue = commission + deliveryRev (client add). Financial sums filter to `delivered` ONLY (spec rule). Note: pre-Session-12 orders sum as 0 — correct, they carried no commission.

## Task C — Finance page

Route reachable only when `currentUser.uid == founderUid` (hidden entry: settings page row visible only to founder — ar `المالية`, en `Finance`). Six stat tiles, calm monochrome, money via money.dart:

إجمالي الطلبات · الطلبات المُسلّمة · الطلبات الملغاة · إجمالي العمولات · إيراد التوصيل · إجمالي إيراد المنصة

Loading = shimmer tiles; error = designed retry; refresh = pull-to-refresh. One line under the header stating the COD reality: ar `أرقام دفترية — التحصيل يتم يدويًا مع المتاجر`, en `Ledger figures — settlement with shops is manual`.

## Task D — Bloc + tests

`FinanceBloc` (load event, parallel `Future.wait` for the six queries, ONE emit — no flicker). Unit test the revenue addition + minor-units formatting boundary.

---

## Smoke Test

- [ ] Founder account: settings shows المالية; page loads six tiles with correct numbers vs. console spot-check.
- [ ] Deliver one more commissioned order → refresh → commission total increases by exactly its `commissionMinor`.
- [ ] Owner + customer + courier accounts: no finance entry anywhere; direct route attempt bounces.
- [ ] Non-founder aggregate query denied by rules (verify owner account can still read own-shop orders normally).
- [ ] Gates green + brand checklist.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_14_ACCEPTANCE.md
```
