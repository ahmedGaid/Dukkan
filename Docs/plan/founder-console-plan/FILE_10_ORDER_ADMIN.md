# SESSION 10 — Order Admin: global board, force-status, reassign, internal notes
# Files: worker/src/admin.js, firestore.rules, firestore.indexes.json,
#        lib/presentation/console/orders/** (new), lib/presentation/orders/order_viewer_role.dart,
#        lib/presentation/orders/pages/order_detail_page.dart, lib/domain/order/** (notes),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/presentation/orders/order_viewer_role.dart` + `order_detail_page.dart` — the
   M10 enum (customer/owner/courier) and how cards gate per role.
2. Open `lib/domain/order/entities/order.dart` — statusHistory, driver fields, commission
   snapshot fields, address shape (where the phone lives).
3. Open `worker/src/admin.js` — routes map; and `firebase.js` — `firestoreCommit`
   (transactions, from Session 2).
4. Open the M9 assignment transaction in `lib/data/driver/…assignDriver` — the validation
   sequence the Worker's reassign must mirror server-side.

Do not write anything yet.

---

## Task A — Worker endpoints

| Route | Perm | Does |
|---|---|---|
| `/admin/orders/force-status` | orders.forceStatus | body `{orderId, toStatus, reason}` (reason REQUIRED; toStatus ∈ the 7 wire strings). One `firestoreCommit` transaction: set `status`, append `statusHistory` entry `{status, at, by: actorUid, forced: true}`, fix side effects — flip `commissionPayable` true iff toStatus == 'delivered'; if leaving an active status and a driver is assigned, decrement `drivers/{driverUid}.activeOrdersCount` (floor 0) exactly like `_advanceStatus` does. Audit with before/after status |
| `/admin/orders/reassign-driver` | orders.assignDriver | body `{orderId, newDriverUid, reason}`. Transaction: validate new driver (online, not suspended, capacity, area — mirror M9 checks), decrement old driver count if assigned, increment new, patch driver block fields (`driverUid/driverName/driverPhone/assignedAt`). Audit. Also allow `{orderId, clear: true}` → unassign (decrement + delete driver fields) |
| `/admin/orders/cancel` | orders.cancel *(add to Permissions + role seeds)* | body `{orderId, reason, refundNoteMinor?}` — transaction: status→'cancelled' (+history, forced flag), driver decrement if needed; `refundNoteMinor` stored on the order (COD: ledger note only, no money moves — comment this). Audit |

Note: the Worker bypasses rules, so the strict client-side transition whitelist stays
untouched — corrections happen ONLY here, always audited, always with a reason.

## Task B — Staff viewer role + rules

- Extend `OrderViewerRole` with `staff`. `order_detail_page.dart`: staff sees ALL existing
  cards (customer contact, payment, driver, timeline) — timeline rows with `forced: true`
  get a small «تصحيح إداري» chip. Router: `?role=staff` accepted only when
  `adminProfile.can(ordersRead)`, else falls back to customer view.
- Internal notes: subcollection `/orders/{orderId}/notes/{noteId}`
  `{text, byUid, byName, at}`; rules block:

```
      match /notes/{noteId} {
        allow read, create: if hasPerm('orders.update');
        allow update, delete: if false;   // notes are append-only
      }
```

  Staff detail gets a notes card (list + add field). Domain: `OrderNote` entity +
  repo methods `watchNotes(orderId)` / `addNote` in the order vertical.

## Task C — Console orders board

- `/console/orders` (section perm orders.read): status filter chips (7 + الكل), shop
  dropdown, area dropdown, date range; search field: order id (direct doc get) or exact
  customer phone (query on the address phone path found in Before-You-Start #2 — add the
  composite index if needed). Paginated createdAt desc.
- Row: short id, shop name, area, `PriceTag` total, status `StatusChip`, driver name or —,
  createdAt. Tap → `/order/:id?role=staff`.
- Staff action bar on the detail page (perm-gated per button): force status (dialog: status
  dropdown + required reason + red warning text), reassign driver (reuse the M9
  `assign_driver_sheet` list UI but submit to the Worker endpoint; include current driver
  header + "إلغاء التعيين" option), cancel+refund-note dialog.
- Deep link `/console/orders?status=pending` — dashboard "orders waiting" quick-action chip
  from Session 5 now wired.
- Audit actions appended: `order.forceStatus`, `order.reassign`, `order.cancel`,
  `order.note` (notes are Firestore-direct + reportAudit).
- Export/print buttons deferred to Session 17 (CSV helper); "print" = share/CSV note.

i18n both ARBs. Lexicon row: Internal note → ملاحظة داخلية.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] wrangler dev: force a delivered order back to preparing → statusHistory gains a
      forced entry, commissionPayable handling correct; force to delivered → payable true,
      driver count decremented once (not twice — verify count).
- [ ] Reassign moves counts old→new atomically; reassign to an offline driver → 4xx with
      reason; clear unassigns.
- [ ] Notes: staff adds a note; second staff sees it realtime; customer/owner/courier
      views never render the notes card; client update/delete of a note → rules deny.
- [ ] Courier + owner regression: their transitions still work under the untouched rules.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_11_DRIVER_ADMIN.md
User action: deploy rules + indexes; wrangler deploy.
```
