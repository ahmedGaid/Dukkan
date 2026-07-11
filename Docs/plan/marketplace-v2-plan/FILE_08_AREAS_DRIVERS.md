# SESSION 8 — Areas + Driver Foundation
# Files: Docs/plan/courier-role-plan/FILE_00_INDEX.md (banner only), lib/domain/auth/entities/user_role.dart, signup flow, lib/domain/driver/** (new), lib/data/driver/** (new), lib/domain/order/entities/address.dart (+order), seed_demo_data.dart, firestore.rules, arb files

---

## Before You Start

1. Open `Docs/plan/courier-role-plan/FILE_00_INDEX.md` — you will stamp it superseded (Task A). Read its "salvage" items: courier shell design, notify pattern, Arabic term مندوب التوصيل.
2. Open `lib/domain/auth/entities/user_role.dart` — read the enum + wire pattern.
3. Open the signup flow (search `UserRole` usages in `presentation/auth/`) — find the role picker.
4. Open `address.dart` (line1/city/notes today) and the checkout page that builds it.

Do not write anything yet.

---

## Task A — Supersede the old plan

Add at the very top of `courier-role-plan/FILE_00_INDEX.md` (only edit to that folder):

```markdown
> **SUPERSEDED 2026-07-11** by `Docs/plan/marketplace-v2-plan/` (Sessions 08–11).
> Decision: shared platform driver pool replaces shop-owned couriers. Do not execute.
```

## Task B — `courier` role

`user_role.dart`: add `courier` with wire string `'courier'` following the existing switch pattern. Signup role picker gains **مندوب التوصيل** / **Courier** (canonical term — add to brand lexicon if missing). Router: courier role → courier shell route (placeholder page this session; real shell in Session 10).

## Task C — Areas

`/areas` collection, seed-managed like `/categories` (read authed, write false). Seed Ismailia districts (verify names against how the 3 real seeded shops describe their locations before committing; adjust list to real coverage):

```
/areas/{areaId}   nameAr: "أبو عطوة"   nameEn: "Abu Atwa"   sort: 1
```

Suggested v1 ids: `abu-atwa`, `el-sheikh-zayed`, `downtown-ismailia`, `el-salam`, `el-quds`.

`Address` entity: add `final String? areaId;` (nullable — old orders keep parsing). Checkout address form: area picker dropdown (required for NEW orders) loading `/areas`. Order doc now carries the areaId inside its embedded address.

## Task D — Driver profile

```
/drivers/{uid}
  name, phone,
  areaIds: ["abu-atwa", ...],
  maxActiveOrders: 5,
  activeOrdersCount: 0,
  isOnline: false,
  isSuspended: true        ← every new driver starts suspended
```

Created at courier signup (defaults above; name/phone from signup). Entity + model + datasource + repo (`getDriver`, `watchDriver`, `setOnline`, plus `availableDrivers(areaId)` query used next session) + DI.

Rules:
- Driver reads/updates OWN doc but ONLY `isOnline` (and name/phone) — never `isSuspended`, `maxActiveOrders`, `areaIds`, `activeOrdersCount` (founder console/seed sets those; count moves only inside the Session 9 transaction, which runs as the owner).
- Shop owners: read access to `/drivers` (needed for the assignment list).

Composite index for the availability query (add to `firestore.indexes.json`): `areaIds array-contains` + `isOnline ==` + `isSuspended ==`.

## Task E — Seed demo drivers

Two demo couriers in seed script: one active (`isSuspended: false, isOnline: true`, areas covering the seeded shops), one suspended — gives Session 9 both list cases.

---

## Smoke Test

- [ ] Old plan index shows SUPERSEDED banner; no other file in that folder changed.
- [ ] Sign up as courier on device → `/users` role `courier`, `/drivers/{uid}` created suspended, lands on placeholder shell.
- [ ] Checkout shows area dropdown; new order doc embeds `areaId`; old orders still open.
- [ ] Courier can flip own `isOnline`; attempt to write own `isSuspended` from a debug call → rules deny.
- [ ] Seeded active driver returned by `availableDrivers('abu-atwa')`; suspended one absent.
- [ ] Gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_09_ASSIGNMENT_TXN.md
```
