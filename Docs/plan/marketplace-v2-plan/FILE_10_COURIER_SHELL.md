# SESSION 10 — Courier Shell
# Files: lib/presentation/driver/** (new: shell, deliveries page, delivery detail, bloc), router, order datasource (courier query + transition), firestore.rules, arb files

---

## Before You Start

1. Open `lib/presentation/shell/home_shell.dart` — copy the shell pattern (owner/customer switch) for the courier variant.
2. Open the order datasource — you add a courier-scoped query + a courier transition path.
3. Re-read the old plan's FILE_04_COURIER_SHELL.md salvage notes (list + detail + ONE primary action button) — design survives, data model is the new one.

Do not write anything yet.

---

## Task A — Courier queries + permissions

- Query: orders where `driverUid == uid` and status in active set (`preparing`, `outForDelivery`), realtime watch; second query/tab for history (`delivered`, last 20).
- Composite index additions to `firestore.indexes.json` as required by those queries.
- Rules: courier reads orders where `resource.data.driverUid == request.auth.uid`; courier may update ONLY `status` (+`statusHistory` append) with exactly two transitions: `preparing→outForDelivery`, `outForDelivery→delivered`. Owner transition rules unchanged.

## Task B — Shell + deliveries list

Courier shell (role-routed from Session 8 placeholder): app bar with **online/offline switch** (writes `isOnline` via Session 8 repo — the driver's one self-serve control), plus suspended banner when `isSuspended` (ar: `حسابك قيد المراجعة — تواصل مع دكان`, en: `Your account is under review — contact Dukkan`).

Active deliveries list: order card = shop name, area, item count, total (money.dart), status chip. Empty state designed: ar `لا توجد توصيلات حاليًا`, en `No deliveries right now`. History tab below/behind a segment.

## Task C — Delivery detail + one primary action

Detail page: customer name/phone (tap-to-call pattern from Session 2), address (line1 + area name), notes, items summary, total. ONE primary button by status:

- `preparing` → **استلمت الطلب** / *Picked up* → transition to `outForDelivery`
- `outForDelivery` → **تم التوصيل** / *Delivered* → transition to `delivered` (confirm dialog — final state)

After transition: update list in place, no Loading refire. Status writes go through the Session 1 path so `statusHistory` records the courier's uid.

## Task D — Bloc + DI

`DeliveriesBloc` (watch active, load history, advance status) + registration. Side effects via `BlocListener`. `buildWhen` guards.

---

## Smoke Test

- [ ] Courier (seeded active driver) logs in → courier shell, online switch works, list shows the order assigned in Session 9.
- [ ] Suspended courier → banner, empty capabilities.
- [ ] Detail: call row, address with area, items, total all render (RTL correct).
- [ ] `استلمت الطلب` → order `outForDelivery`; customer's order page reflects it live; timeline shows courier uid.
- [ ] `تم التوصيل` → confirm → `delivered`; order leaves active list, appears in history; driver count decremented (Session 9 hook).
- [ ] Courier attempting owner-only transition via debug write → rules deny.
- [ ] Gates green + brand checklist on the new screens.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_11_DRIVER_NOTIFY.md
```
