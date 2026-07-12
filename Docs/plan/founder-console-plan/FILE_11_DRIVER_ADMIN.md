# SESSION 11 — Driver Admin: activation, areas, capacity, vehicle, performance
# Files: firestore.rules, lib/domain/driver/entities/driver.dart + model,
#        lib/presentation/console/drivers/** (new), worker/src/index.js (ALLOWED_FOLDERS),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/domain/driver/entities/driver.dart` + `driver_model.dart` — M8 fields
   (areaIds, maxActiveOrders, activeOrdersCount, isOnline, isSuspended, name, phone).
2. Open `firestore.rules` `/drivers` — the self-write whitelist + count-bump branch.
3. Open the M13 finance datasource — aggregate pattern for the performance numbers.
4. Open `worker/src/index.js` — `ALLOWED_FOLDERS` set.

Do not write anything yet.

---

## Task A — Fields + rules

`Driver` entity/model additive fields: `vehicleType` (string?, e.g. «موتوسيكل»),
`vehiclePlate` (string?), `idDocUrl` (string?), `isVerified` (default false),
`suspendReason` (string?).

Rules `/drivers` update — add the staff branch:

```
        || (hasPerm('drivers.manage')
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
               'isSuspended', 'suspendReason', 'areaIds', 'maxActiveOrders',
               'vehicleType', 'vehiclePlate', 'idDocUrl', 'isVerified',
               'name', 'phone']))
```

(`activeOrdersCount` stays out — only the bump branch and the Worker touch it.)

`worker/src/index.js`: add `'driver-docs'` to `ALLOWED_FOLDERS` (ID-document photo
uploads ride the existing `/upload`).

## Task B — Console drivers page

`/console/drivers` (section perm drivers.manage). **This kills the last recurring
Firebase-console chore: activating a new driver.**

- List: filter chips (بانتظار التفعيل = isSuspended && !isVerified, نشط, موقوف, متصل الآن),
  row = name, phone, online dot, active/max load («2/3»), area chips, verified badge.
- Detail sheet/page:
  - activate/suspend switch (+ required reason when suspending),
  - verified toggle,
  - areas multi-select (from the areas repo — all areas incl. inactive, labeled),
  - `maxActiveOrders` stepper (1–10),
  - vehicle fields + ID-document image (upload via `/upload?folder=driver-docs`,
    preview if set),
  - performance card: `orders.where(driverUid==uid, status=='delivered').count()` +
    current active count + this-month delivered count (aggregate, createdAt window),
  - assigned orders list: `orders.where(driverUid==uid, status in
    ['preparing','outForDelivery'])` → rows link to `/order/:id?role=staff`.
- Every mutation Firestore-direct + `reportAudit` (`driver.activate`, `driver.suspend`,
  `driver.verify`, `driver.update`) — append to `audit_actions.dart`.
- Dashboard driversOnline tile cross-checked.
- Driver ratings: SKIPPED — no rating data exists for drivers (only shops); note as
  future work, don't fake it.

Courier-side ripple: the M10 suspended banner already reads `isSuspended` — a suspension
from console takes effect on the courier's next stream event (verify, no code needed).

i18n both ARBs. Lexicon rows: Activate → تفعيل · Vehicle → المركبة.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Model test: old driver doc (no vehicle fields) parses.
- [ ] Console: flip the SEEDED suspended demo driver to active → they appear in the M9
      owner assignment sheet immediately; suspend again → gone + courier shell shows the
      suspended banner.
- [ ] Staff CANNOT edit activeOrdersCount from console (no UI) and a handcrafted write
      touching it is rules-denied.
- [ ] ID-doc upload lands in R2 under `driver-docs/` and previews.
- [ ] Performance numbers match a hand count of the seed data.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_12_PLATFORM_SETTINGS.md
User action: deploy rules; wrangler deploy (ALLOWED_FOLDERS).
```
