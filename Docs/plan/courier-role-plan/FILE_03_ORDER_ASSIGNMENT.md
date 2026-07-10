# SESSION 3 — Order Assignment (owner → courier)
# Files: lib/domain/order/entities/order.dart, lib/data/order/models/* (order model),
#        lib/domain/order/repositories/order_repository.dart, lib/domain/order/usecases/assign_courier.dart (NEW),
#        lib/data/order/** (datasource + repo impl), order-desk detail UI (S3 pages),
#        firestore.rules, lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb, tests

---

## Before You Start

1. Recall `dukkan-flutter` + `dukkan-brand`.
2. Open `lib/domain/order/entities/order.dart` → read the whole entity (courierUid goes here).
3. Open `lib/data/order/models/` → read the order model's fromFirestore/toFirestore/copy logic.
4. Open `lib/domain/order/entities/order_status.dart` + `lib/domain/order/usecases/update_order_status.dart` → understand how status advances are modeled.
5. Open the S3 order-desk pages under `lib/presentation/` (search for "order desk" / `orderPrimaryAction`) → find where the owner's status action buttons render for an `accepted`/`preparing` order.
6. Open `firestore.rules` → re-read the whole `/orders/{orderId}` match (functions `isOrderOwner`, `isShopOwner`, `isValidOwnerTransition`).

Do not write anything yet.

---

## Task A — Entity + model

In `order.dart`, after the `rating` field, add:

```dart
/// Uid of the courier (مندوب التوصيل) the owner assigned to deliver this
/// order (D3), or null when the shop delivers itself. Set while the order is
/// accepted/preparing; the assigned courier advances the delivery statuses.
final String? courierUid;
```

Add it to the constructor (`this.courierUid`) and to `props`. Update the order model:
read `courierUid` from the doc (nullable), write it only when non-null, and thread it through
any `copyWith`/factory the model has.

## Task B — Firestore rules

In `firestore.rules`, `/orders/{orderId}` match:

1. Add a helper next to `isShopOwner()`:

```
function isAssignedCourier() {
  return isSignedIn() && resource.data.get('courierUid', '') == request.auth.uid;
}
```

2. Extend read:

```
allow read: if isOrderOwner() || isShopOwner() || isAssignedCourier();
```

3. Add two clauses to the `allow update` chain (keep the three existing clauses untouched):

```
// Owner assigns/reassigns a courier while the order is being worked (D3).
|| (isShopOwner()
  && resource.data.status in ['accepted', 'preparing']
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['courierUid']))
// The assigned courier advances only the delivery legs (D3).
|| (isAssignedCourier()
  && ((resource.data.status == 'preparing'
        && request.resource.data.status == 'outForDelivery')
    || (resource.data.status == 'outForDelivery'
        && request.resource.data.status == 'delivered'))
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']))
```

Owner transitions (`isValidOwnerTransition`) stay valid — self-delivery unchanged. Deploy rules.

**Note:** the courier's home screen (session 4) queries `/orders` with
`where('courierUid', isEqualTo: uid)` — list reads pass because every matched doc satisfies
`isAssignedCourier()`. A composite index (`courierUid` + `createdAt`) will be requested by
Firestore on first run; capture the link.

## Task C — Domain + data

- `order_repository.dart`: add `assignCourier(String orderId, String courierUid)` (and follow the
  repo's Either/Failure style). If existing code exposes streams of shop orders, no read changes
  are needed here — courier reads come in session 4.
- Datasource + repo impl: `assignCourier` = `update({'courierUid': courierUid})`.
- New usecase `lib/domain/order/usecases/assign_courier.dart`, registered in `injector.dart`.
- Check `update_order_status.dart` / the order-status view helpers: the owner's
  `preparing → outForDelivery` action must STILL be offered (fallback), so no removal — only add
  the assign affordance.

## Task D — Order-desk UI: assign action

On the order-desk order detail (statuses `accepted` or `preparing`), add an "المندوب" row:

- If the shop has no couriers (session 2's `GetShopCouriers` returns empty) → render nothing
  (owner self-delivery UX identical to today).
- Else render a row: label `l10n.courierAssignLabel` + current assignee name (or
  `l10n.courierUnassigned`) + a change/assign affordance opening a bottom sheet listing the
  shop's couriers (name + phone); tapping one calls `AssignCourier` and updates optimistically
  (Shoppy lesson: no reload flash).
- Reuse existing bottom-sheet / list-tile primitives; match the order-desk visual language.
- Assigned courier name should also show on the order card/detail wherever the status stepper
  lives, as one quiet line — not a badge, not colored.

Where the bloc lives: extend the existing order-desk bloc with an `AssignCourierRequested` event
rather than creating a new bloc — read the bloc first and match its event/state shape.

## Task E — i18n + tests

Keys (ar + en): `courierAssignLabel` ("المندوب"), `courierUnassigned` ("بدون مندوب"),
`courierAssignSheetTitle` ("اختر المندوب"), `courierAssigned` (snackbar "تم إسناد الطلب إلى {name}"
— follow existing placeholder style in the arb files). Run `flutter gen-l10n`.

Tests: model round-trip with/without `courierUid`; `assignCourier` repo test; bloc test for the
assign event (mock usecase). Keep the existing 56+ tests green.

---

## Smoke Test

- [ ] Gates green (analyze / test / parity).
- [ ] Customer places an order → owner accepts → "المندوب" row appears (shop has 1 courier from session 2).
- [ ] Assign the courier via bottom sheet → snackbar, name shows on the order, Firestore doc gains `courierUid`.
- [ ] Reassign while `preparing` works; assigning after `outForDelivery` is not offered (and rules would reject it).
- [ ] Owner WITHOUT couriers sees the order desk exactly as before (no assign row).
- [ ] Owner can still advance `preparing → outForDelivery → delivered` himself on an unassigned order.
- [ ] Rules check: the courier account can read the assigned order doc; a different courier cannot.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, mark D3, commit + push
→ Clear session, then open FILE_04_COURIER_SHELL.md and continue
```
