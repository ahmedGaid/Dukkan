# SESSION 9 — Driver Assignment (Transaction + Owner Screen)
# Files: lib/data/driver/datasources (txn), driver repo + new use case, lib/domain/order/entities/order.dart (+model), order_detail_page.dart / order_desk_page.dart, firestore.rules, arb files

---

## Before You Start

1. Re-read Session 8's driver datasource + rules as landed.
2. Open `order.dart`/`order_model.dart` — you add driver fields next to `statusHistory`.
3. Open the owner order detail page — the driver placeholder block from Session 2 gets real now.

Do not write anything yet.

---

## Task A — Order driver fields

`Order`: `final String? driverUid; final String? driverName; final String? driverPhone; final DateTime? assignedAt;` (denormalized name/phone — customer + owner display without extra reads; all nullable, old docs parse). Model + props + datasource passthrough.

## Task B — The assignment transaction

New use case `AssignDriver(orderId, driverUid)`; datasource core:

```dart
await firestore.runTransaction((txn) async {
  final driverRef = firestore.doc('drivers/$driverUid');
  final orderRef = firestore.doc('orders/$orderId');
  final driver = await txn.get(driverRef);
  final order = await txn.get(orderRef);

  final active = driver.get('activeOrdersCount') as int;
  final max = driver.get('maxActiveOrders') as int;
  final areas = List<String>.from(driver.get('areaIds'));
  final orderArea = order.get('deliveryAddress.areaId') as String?;
  final status = order.get('status') as String;

  if (driver.get('isSuspended') == true) throw DriverUnavailable('suspended');
  if (driver.get('isOnline') != true) throw DriverUnavailable('offline');
  if (active >= max) throw DriverUnavailable('capacity');
  if (orderArea == null || !areas.contains(orderArea)) throw DriverUnavailable('area');
  if (status != 'accepted' && status != 'preparing') throw DriverUnavailable('status');
  if (order.get('driverUid') != null) throw DriverUnavailable('taken');

  txn.update(driverRef, {'activeOrdersCount': active + 1});
  txn.update(orderRef, {
    'driverUid': driverUid,
    'driverName': driver.get('name'),
    'driverPhone': driver.get('phone'),
    'assignedAt': DateTime.now().toIso8601String(),
  });
});
```

(Adapt field-access style + error types to the codebase's `core/errors` conventions. `DriverUnavailable` carries a reason mapped to localized copy.) Two owners racing for the last slot: second transaction retries, re-reads `active == max`, fails clean — exactly the spec's validation-at-assignment rule.

**Decrement**: in the status-update datasource path (Session 1), when a driver-carrying order reaches `delivered`, `cancelled`, or `rejected`, decrement `activeOrdersCount` (transaction, floor at 0).

Rules: allow the shop owner to update `drivers/{uid}.activeOrdersCount` by exactly ±1 and order driver fields only while owner of the order's shop — keep it as tight as the rule language allows; note in a comment that a Worker endpoint is the future hardening path.

## Task C — Owner assignment sheet

On owner order details, when status is `accepted`/`preparing` and no driver: button **تعيين مندوب** / **Assign courier** → bottom sheet:

- List from `availableDrivers(order.deliveryAddress.areaId)`, each row: name, areas (localized names via areas repo), capacity as `٢ / ٥` style via existing number formatting.
- Client-side also hides full drivers (`activeOrdersCount >= maxActiveOrders`) — index query from Session 8 can't compare two fields.
- Empty list → designed state: ar `لا يوجد مندوبون متاحون الآن — يمكنك التوصيل بنفسك`, en `No couriers available right now — you can deliver it yourself` (keeps self-delivery visible as the fallback).
- Tap driver → confirm → run use case → success: sheet closes, driver block on details fills (name, phone, assigned time). Failure: `AppSnackBar.error` with the reason-specific message (offline/capacity/area/taken) — blame-free copy.
- Order with driver assigned: block shows driver + assigned time; owner transitions continue working unchanged (self-delivery orders never blocked on a driver).

## Task D — Customer view

Customer order detail: once `driverUid` set, show driver name (+ phone row) in the existing detail layout — customers see who's coming.

---

## Smoke Test

- [ ] Owner assigns seeded active driver to an `accepted` order in a matching area → order doc gets driver fields, driver count 0→1.
- [ ] Same driver at `maxActiveOrders` (set via console) → not listed; forced call fails with capacity message.
- [ ] Driver offline (flip via courier account) mid-flow → assignment rejected with offline message.
- [ ] Order in an area the driver lacks → not listed.
- [ ] Deliver the order → driver count decrements.
- [ ] Order without driver: owner advances statuses exactly as before (fallback intact).
- [ ] Gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_10_COURIER_SHELL.md
```
