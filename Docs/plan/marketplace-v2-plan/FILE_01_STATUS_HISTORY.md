# SESSION 1 — Status History Log
# Files: lib/domain/order/entities/status_change.dart (new), order.dart, lib/data/order/models/order_model.dart, lib/data/order/datasources/order_remote_datasource.dart, firestore.rules

---

## Before You Start

1. Open `lib/domain/order/entities/order.dart` — read the `Order` entity (fields end at `rating`).
2. Open `lib/data/order/models/order_model.dart` — read `fromDoc`/`toMap` (names may differ — confirm actual parse/serialize method names).
3. Open `lib/data/order/datasources/order_remote_datasource.dart` — find the method that CREATES an order and the method that UPDATES `status` (owner desk + customer cancel both route here).
4. Open `firestore.rules` — find the `/orders` match block; note how status updates are validated today.

Do not write anything yet.

---

## Task A — `StatusChange` entity

Create `lib/domain/order/entities/status_change.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'order_status.dart';

/// One row of the order timeline. Appended on create and on every
/// transition — never edited, never removed.
class StatusChange extends Equatable {
  const StatusChange({
    required this.status,
    required this.at,
    required this.byUid,
  });

  final OrderStatus status;
  final DateTime at;
  final String byUid;

  @override
  List<Object?> get props => [status, at, byUid];
}
```

## Task B — Add `statusHistory` to `Order`

In `order.dart`, add after `rating`:

```dart
  /// Timeline of every status the order has held, oldest first. Empty list
  /// for orders created before this field existed (seeded v1 orders).
  final List<StatusChange> statusHistory;
```

Constructor: `this.statusHistory = const []` (optional — old docs must keep parsing). Add to `props`.

## Task C — Model + wire format

In `order_model.dart`, serialize as an array of maps on the order doc:

```dart
'statusHistory': statusHistory
    .map((c) => {
          'status': c.status.wire,
          'at': c.at.toIso8601String(),
          'byUid': c.byUid,
        })
    .toList(),
```

Parse side: missing field → `const []`. Follow the existing timestamp convention (ISO strings before model parsing — see datasource).

## Task D — Append on create + transition

In `order_remote_datasource.dart`:

- **Create:** when building the new order map, include `statusHistory` with one entry (`pending`, now, customerUid).
- **Status update:** wherever `status` is written, change the update to also append:

```dart
await docRef.update({
  'status': next.wire,
  'statusHistory': FieldValue.arrayUnion([
    {
      'status': next.wire,
      'at': DateTime.now().toIso8601String(),
      'byUid': currentUid,
    }
  ]),
});
```

`currentUid` = FirebaseAuth current user (owner or customer) — pass it in the same way the datasource already gets the uid for queries. If BOTH owner desk and customer cancel go through ONE datasource method, one edit covers all transitions — confirm in Before You Start step 3.

## Task E — Rules

In `firestore.rules` `/orders` update block, allow `statusHistory` alongside `status` in the permitted-update key set (pattern depends on how the block is written today — extend, don't rewrite). Deploy: `firebase deploy --only firestore:rules` (user-side if CLI login unavailable in agent shell).

---

## Smoke Test

- [ ] `flutter analyze` → 0 issues; `flutter test` → green.
- [ ] Place a new order on device → Firestore console shows `statusHistory` with one `pending` entry.
- [ ] Owner advances it to `accepted` → array has two entries, correct uids.
- [ ] Customer cancels a fresh pending order → `cancelled` entry appended.
- [ ] Old seeded orders (no field) still open in both order lists without crash.

---

## After This Session

```
Smoke test passed?
→ gates green → update dukkan-status → commit
→ /compact → open FILE_02_OWNER_ORDER_DETAILS.md
```
