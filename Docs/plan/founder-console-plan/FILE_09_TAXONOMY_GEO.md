# SESSION 9 — Taxonomy + Geographic Management: everything editable
# Files: firestore.rules, lib/domain/taxonomy/** + lib/data/taxonomy/** (extend),
#        lib/domain/areas/** + lib/data/areas/** (extend),
#        lib/presentation/console/taxonomy/** (new), lib/presentation/console/geo/** (new),
#        checkout area dropdown + home CategoryGrid + product form (visibility/sort respect),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/domain/taxonomy/` + `lib/data/taxonomy/` — the M3 doc shape for
   `/categories/{id}` (names, subcategories representation, any sort field) and the
   local-cache pattern. THE PLAN DOES NOT GUESS THIS SHAPE — read it first.
2. Open `lib/domain/areas/` + `lib/data/areas/` — M8 area shape + one-shot cache.
3. Open home `CategoryGrid` + product-form dropdowns (M4/M5) — how taxonomy is consumed.
4. Open checkout's area dropdown (M8).
5. Open `firestore.rules` — `/categories` + `/areas` blocks (`write: false` today).

Do not write anything yet.

---

## Task A — Rules: console-managed instead of seed-managed

```
    match /categories/{categoryId} {
      allow read: if isSignedIn();
      allow create, update, delete: if hasPerm('taxonomy.edit');
    }
    match /areas/{areaId} {
      allow read: if isSignedIn();
      allow create, update, delete: if hasPerm('geo.edit');
    }
```

Update the seed-script comments (the relax-then-restore dance dies for these two —
console IS the write path now; seeding still works when signed in as founder).

## Task B — Taxonomy fields + console CRUD

Category doc gains (additive, defaults): `sort` (int), `isVisible` (default true),
`iconName` (string key into a curated `Map<String, IconData>` in
`lib/presentation/console/taxonomy/category_icons.dart` — Material icons are const, no
dynamic lookup exists; ~20 grocery-relevant options). Subcategories: match whatever M3
shape exists (embedded array vs subcollection) — extend in place with `sort`/`isVisible`
per subcategory if the shape allows without migration.

Console page `/console/taxonomy` (perm taxonomy.edit): category list ordered by `sort`
with up/down reorder buttons (swap sort values — no drag dep), visibility eye-toggle,
edit sheet (nameAr required, nameEn required, icon picker grid), add/delete. Delete with
products still referencing → warning dialog with the count (`products.where(category==…)
.count()`) + proceed allowed (stale-reference-safe rendering already exists — same
pattern as deleted collections, M6).

Consumers: taxonomy repository mapping now sorts by `sort` and drops `isVisible == false`
for CUSTOMER surfaces (home grid, product-form dropdowns keep showing hidden ones to
owners? No — hidden means retired: exclude from the form too; existing products keep the
stale id and render fine). Cache: bump/flush the local taxonomy cache on console edits
(check the M3 cache for a version/invalidations hook; simplest: console writes also clear
the local cache instance via the repository).

## Task C — Geo fields + console CRUD

Area doc gains (additive): `governorate` (string, default 'الإسماعيلية'), `city` (string,
default 'الإسماعيلية'), `isActive` (default true), `deliveryFeeMinorOverride`
(int?, null = platform default; **piasters**).

Console page `/console/geo` (perm geo.edit): grouped list governorate → city → areas;
add/edit sheet (names, governorate/city text with autocomplete from existing values,
active toggle, fee override money field), deactivate instead of delete when orders
reference the area (count check like taxonomy).

Consumers: checkout dropdown filters `isActive`; if `deliveryFeeMinorOverride` set, M12's
`PlaceOrder` snapshot uses it instead of `PlatformConfig.deliveryFeeMinor` (touch the
use case; add a unit test). Countries/postal codes: deliberately NOT built (Egypt-only —
locked in index).

Audit: `taxonomy.create/update/delete`, `area.create/update/delete` via `reportAudit` +
`audit_actions.dart`.

i18n both ARBs. Lexicon rows: Governorate → المحافظة · City → المدينة (check BRAND.md
first — may exist).

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Old category/area docs parse unchanged (model tests with minimal docs).
- [ ] Hide a category in console → gone from home grid + product form after cache flush;
      existing products in it still render on shop page.
- [ ] Reorder persists and home grid follows.
- [ ] New area appears in checkout; deactivated area disappears; fee override lands in a
      new order's `deliveryFeeMinor` snapshot (place a test order).
- [ ] Non-geo.edit staff: direct `/areas` write denied by rules.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_10_ORDER_ADMIN.md
User action: deploy rules.
```
