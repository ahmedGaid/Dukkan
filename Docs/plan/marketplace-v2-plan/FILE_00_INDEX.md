# Marketplace V2 Plan — Master Index

> **Load this file first in every session.** Then open the ONE session file you are executing.
> Runs AFTER roadmap R1 (store screenshots) + R2 (signed build / Play upload).
> **Supersedes `Docs/plan/courier-role-plan/` entirely** (decision 2026-07-11: shared platform
> driver pool replaces shop-owned couriers). Session 08 stamps the old plan SUPERSEDED.

## Project Goal

Five features, one plan: (A) owner order details + status timeline, (B) global seed-managed
category/subcategory taxonomy, (C) shop collections + home chips polish, (D) shared delivery
driver pool with areas + capacity, (E) platform commission ledger + finance summary. All
Firestore-direct (no API layer), all Arabic-first, all backward compatible with the 7 live
seeded shops / 53 products / 7 orders.

## Locked decisions (do not reopen mid-session)

| Decision | Choice |
|---|---|
| Order status enum | UNCHANGED — `pending→accepted→preparing→outForDelivery→delivered\|cancelled\|rejected`. No `readyForPickup`, no `pickedUp`. |
| Status history | `statusHistory` array on order doc, appended on create + every transition |
| Taxonomy admin | Seed-managed fixed taxonomy in `/categories` — no admin console, no owner-created categories |
| Product taxonomy link | `subcategoryId` on product; parent category derived via taxonomy lookup |
| Shop collections | `/shops/{shopId}/collections` subcollection; product holds `collectionIds` array |
| Driver model | Platform-level pool. `/users` role `courier` + `/drivers/{uid}` profile: `areaIds`, `maxActiveOrders`, `activeOrdersCount`, `isOnline`, `isSuspended` (new driver starts suspended; founder activates via console/seed) |
| Areas | `/areas` collection seeded with Ismailia districts; `areaId` on address + order |
| Assignment | Owner assigns during `accepted`/`preparing`, Firestore **transaction** on driver doc (validate online + capacity + area, increment count). Owner self-delivery fallback stays. |
| Courier Arabic term | **مندوب التوصيل** (short: مندوب). Never ديليفري/طيار. |
| Commission | Snapshot at order creation: `commissionBps`, `commissionMinor`, `deliveryFeeMinor`, `driverDeliveryShareMinor`, `platformDeliveryShareMinor`. Integer piasters + basis points, round-half-up. `commissionPayable` flips true at `delivered`; cancelled/rejected keep numbers, payable stays false. COD reality: ledger only — no money moves. |
| Platform config | `/config/platform` doc (`commissionBps`, `driverDeliveryShareMinor`), client-readable, client-UNwritable, seed-managed |
| Finance summary | Firestore aggregate queries (`count()`/`sum()`), screen gated to founder uid |

## Affected files (exhaustive)

- `lib/domain/order/entities/` — `order.dart`, `+status_change.dart`
- `lib/data/order/` — `order_model.dart`, `order_remote_datasource.dart`, repository impl
- `lib/presentation/orders/pages/order_desk_page.dart`, `order_detail_page.dart`
- `lib/domain/product/entities/product.dart` + product model/datasource
- `lib/presentation/catalog/pages/product_form_page.dart`, `catalog_manager_page.dart`
- `lib/presentation/home/` — chips + bloc; `lib/presentation/shop/pages/shop_page.dart`
- NEW feature folders: `taxonomy/`, `collections/`, `driver/`, `finance/` (domain/data/presentation each)
- `lib/domain/auth/entities/user_role.dart`, signup flow
- `lib/dev/seed_demo_data.dart`, `firestore.rules`, `firestore.indexes.json`
- `lib/l10n/app_ar.arb` + `app_en.arb` (every new string, both files)
- `lib/core/di/` service locator, `lib/core/router/`

## Never touch

- `lib/core/money.dart` internals (consume it, don't edit it)
- `worker/` (deploy is user-side; only NEW notify types allowed in Session 11)
- `lib/firebase_options.dart`, `android/` signing config
- Old plan `Docs/plan/courier-role-plan/` content (banner stamp only, Session 08)
- Existing 7-status enum wire strings

## Session Map

| # | File | What gets built | Est. |
|---|---|---|---|
| 01 | FILE_01_STATUS_HISTORY.md | `statusHistory` on order: entity, model, datasource append, rules | 20 min |
| 02 | FILE_02_OWNER_ORDER_DETAILS.md | Owner order details: full fields + timeline UI | 25 min |
| 03 | FILE_03_TAXONOMY_DATA.md | `/categories` seed, taxonomy entities/repo, `subcategoryId` on product, backfill | 25 min |
| 04 | FILE_04_PRODUCT_FORM_DROPDOWNS.md | Dependent category→subcategory dropdowns + validation + search | 20 min |
| 05 | FILE_05_CATEGORY_BROWSE.md | Home chips polish + selection preserved into shop page filter | 25 min |
| 06 | FILE_06_COLLECTIONS_DATA.md | Collections subcollection + owner CRUD screen | 25 min |
| 07 | FILE_07_COLLECTIONS_UI.md | Assign products to collections + customer shop-page rows | 20 min |
| 08 | FILE_08_AREAS_DRIVERS.md | Areas seed, courier role, driver profile, rules, old-plan SUPERSEDED stamp | 25 min |
| 09 | FILE_09_ASSIGNMENT_TXN.md | Assignment transaction + owner "assign driver" sheet | 25 min |
| 10 | FILE_10_COURIER_SHELL.md | Courier shell: deliveries list, detail, advance-status button | 30 min |
| 11 | FILE_11_DRIVER_NOTIFY.md | Assignment push via Worker `/notify` + self-delivery regression pass | 20 min |
| 12 | FILE_12_COMMISSION_LEDGER.md | `/config/platform`, checkout snapshot fields, payable flip, rules | 25 min |
| 13 | FILE_13_FINANCE_SUMMARY.md | Founder-gated finance screen, aggregate queries | 20 min |
| 14 | FILE_14_ACCEPTANCE.md | Full acceptance + regression + sign-off | 30 min |

## Ground Rules (every session)

1. **Read before write.** Every session starts with its "Before You Start" reads — no blind edits.
2. **Additive only.** Existing wire strings, doc fields, and rules keep working; new fields optional-with-default so the 7 seeded orders still parse.
3. **i18n parity is build-blocking.** Every user-facing string → key in BOTH `app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`.
4. **Money = integer piasters; percent = integer basis points.** No doubles, format only via `core/money.dart`.
5. **Layers.** Page → BLoC event → use case → repository → datasource. No shortcuts. DI order: datasource → repo → use case → bloc.
6. **Gates before "done":** `flutter analyze` (0), `flutter test` (green), `dart run scripts/check_i18n_parity.dart`. UI work also passes the `dukkan-brand` feel checklist.

## How to use this plan

1. Fresh session → load `FILE_00_INDEX.md` (this file) → open the next unchecked session file.
2. Execute tasks in order, run the smoke test, run the gates.
3. Update the `dukkan-status` skill (position + NEXT ACTION), commit, `/compact` or fresh session, next file.

## After all sessions complete

- Run FILE_14 acceptance + regression in full on device `R5CNC0NK6ZT`.
- Re-run E2E master prompt (`Docs/testing/E2E_MASTER_PROMPT.md`) — extend it with driver + commission steps.
- Deploy updated `firestore.rules` + `firestore.indexes.json`; re-seed; delete `Docs/plan/courier-role-plan` reference from roadmap NEXT pointers (folder itself stays as archive).

*Generated by ag-plan skill. Do not edit this index manually.*
