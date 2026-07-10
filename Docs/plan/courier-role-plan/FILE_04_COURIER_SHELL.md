# SESSION 4 — Courier Shell (deliveries list + actions)
# Files: lib/presentation/courier/** (shell, bloc, deliveries page, delivery detail page),
#        lib/domain/order/repositories/order_repository.dart + usecases (watch courier orders NEW),
#        lib/data/order/** (courier query), lib/core/router/app_router.dart,
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb, tests

---

## Before You Start

1. Recall `dukkan-brand` + `dukkan-flutter`.
2. Open the customer orders page (C4) under `lib/presentation/orders/` → read how it watches
   orders realtime (Firestore snapshots → bloc), how the status stepper renders, and how the
   list/empty/error/loading states are built. **This session is mostly that pattern, re-skinned.**
3. Open `lib/presentation/shell/owner_home_shell.dart` → note how a role shell composes tabs/AppBar.
4. Open session 1's `courier_home_shell.dart` placeholder — it gets replaced now.
5. Open `lib/domain/order/entities/order_status.dart` → note enum values + any label/color helpers.

Do not write anything yet.

---

## Task A — Data: courier order streams

Order repository: add `watchCourierOrders(String courierUid)` returning the same stream shape the
customer/owner watchers use. Datasource query:

```dart
firestore
    .collection('orders')
    .where('courierUid', isEqualTo: courierUid)
    .orderBy('createdAt', descending: true)
    .snapshots()
```

First run will demand a composite index (courierUid + createdAt) — create it via the printed link.
Split into active vs history **client-side** (active = `preparing`, `outForDelivery`; history =
`delivered` + anything else) — one query, no second index.

Usecase `watch_courier_orders.dart`, registered in DI.

## Task B — CourierBloc

`lib/presentation/courier/bloc/courier_bloc.dart` (+ events/states files if the codebase splits
them): subscribes to `WatchCourierOrders` for the signed-in uid, emits loading/loaded/error;
loaded state carries `active` and `history` lists. Status advance goes through the existing
`UpdateOrderStatus` usecase (it is a plain status write — rules now allow the courier the two
delivery legs). Optimistic update on advance, rollback + snackbar on failure (same pattern as C4
cancel).

## Task C — Real CourierHomeShell

Replace the session-1 placeholder body of `courier_home_shell.dart` with the real shell:

- AppBar: title `l10n.courierDeliveriesTitle` ("توصيلاتي"), one action = join-shop entry
  (`Icons.add`, tooltip `l10n.courierJoinShopTitle`) pushing `/courier/join`; plus the standard
  settings entry if other shells expose one — match owner shell.
- Body: two segments (active / history) — reuse whatever segmented/tab primitive the app already
  has (check C4 orders page first; if it has none, two `Tab`s in a `TabBar` styled like existing
  tabs).
- Active list: one card per order — shop name, 2-line address, item count + `totalMinor`
  (format via the existing money formatter ONLY), `StatusChip`, and the customer phone as a
  tappable row (launch `tel:` via the pattern already used anywhere in the app; if `url_launcher`
  is not already a dependency, show the number copy-on-tap instead — **no new deps**).
- Empty states, designed: no memberships yet → session 1's join prompt; member but no assigned
  orders → `l10n.courierNoActiveTitle`/`Body` ("لا توصيلات نشطة" / "الطلبات الجديدة هتظهر هنا أول ما
  صاحب الدكان يسندها لك."). Error + loading (shimmer) states match C4.

## Task D — Delivery detail + actions

`lib/presentation/courier/pages/delivery_detail_page.dart`, route `/courier/order/:id`
(register in `app_router.dart`; guard nothing extra — rules protect the data):

- Reuse the C4 order-detail composition: status stepper, items list, totals, address block —
  extract shared widgets ONLY if C4 already factored them; otherwise compose from primitives,
  do not fork-copy 200 lines.
- Primary action button (bottom, full width, `AppButton`):
  - status `preparing` → `l10n.actionStartDelivery` ("استلمت الطلب") → advances to `outForDelivery`.
  - status `outForDelivery` → `l10n.actionMarkDelivered` ("تم التسليم") → advances to `delivered`,
    with a confirm dialog (`l10n.confirmMarkDelivered`) — delivered is terminal and it unlocks the
    customer's rating, so no accidental taps.
  - any other status → no button, status stepper tells the story.

## Task E — i18n + tests

Keys (ar + en): `courierDeliveriesTitle`, `courierActiveTab`, `courierHistoryTab`,
`courierNoActiveTitle`, `courierNoActiveBody`, `courierNoHistoryTitle`, `actionStartDelivery`,
`actionMarkDelivered`, `confirmMarkDelivered`, `courierCallCustomer`. Run `flutter gen-l10n`.

Tests: CourierBloc (stream emits → states; advance event → optimistic update + usecase called;
failure → rollback). Match existing bloc-test style.

---

## Smoke Test

- [ ] Gates green (analyze / test / parity).
- [ ] Full loop on device: customer orders → owner accepts + prepares + assigns courier →
      courier's active list shows the order in realtime (no manual refresh).
- [ ] Courier taps order → detail → "استلمت الطلب" → customer's order stepper moves to
      "في الطريق" in realtime.
- [ ] "تم التسليم" (with confirm) → order lands in courier history; customer sees delivered +
      can rate (P3 flow intact).
- [ ] Owner order desk reflects courier-driven status changes in realtime.
- [ ] Courier with no assignments sees the designed empty state; RTL layout clean; dark mode clean.
- [ ] Second courier account sees nothing of the first courier's orders.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, mark D4, commit + push
→ Clear session, then open FILE_05_NOTIFICATIONS.md and continue
```
