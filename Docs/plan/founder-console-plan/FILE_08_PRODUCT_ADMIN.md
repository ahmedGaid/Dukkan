# SESSION 8 — Product Admin: cross-shop board, soft delete, bulk operations
# Files: lib/domain/product/entities/product.dart + model/datasource, firestore.rules,
#        lib/presentation/console/products/** (new), lib/presentation/catalog/pages/product_form_page.dart,
#        firestore.indexes.json, lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/domain/product/entities/product.dart` + `product_model.dart` — current fields
   (shopId, name/nameAr, imageUrl, priceMinor, category, subcategoryId, collectionIds,
   stockStatus, isPromo …verify exact list).
2. Open `product_form_page.dart` — it already takes `shopId` + optional `product`;
   check what, if anything, assumes the caller is the shop owner.
3. Open `firestore.rules` `/products` — `ownsShop()` branches.
4. Open the customer product queries (shop page ProductsBloc + search) — where a
   `deleted` filter must apply client-side.

Do not write anything yet.

---

## Task A — Fields (additive)

`Product`: add `isFeatured` (default false), `deleted`/`deletedAt`/`deletedBy` (soft
delete, default absent). Spec's "archive" maps to soft delete (one hide mechanism, not
two — restore anytime; deliberate simplification, note in code comment). Customer-facing
queries drop `deleted` docs client-side in the repository impl (same pattern as shops).

## Task B — Rules

`/products`: add staff branches alongside `ownsShop`:

```
      allow create: if ownsShop(request.resource.data.shopId) || hasPerm('products.create');
      allow update: if (ownsShop(resource.data.shopId) || hasPerm('products.update'))
        && request.resource.data.shopId == resource.data.shopId;
      allow delete: if ownsShop(resource.data.shopId) || hasPerm('products.delete');
```

(hard `delete` stays possible for owners as today; console uses soft delete except an
explicit founder-only "delete forever" on already-soft-deleted docs.)

## Task C — Console products board

- `/console/products` (section perm products.update): filters — shop dropdown (all shops,
  from console shops repo), category, stockStatus, isPromo, deleted-only toggle;
  search by name (Arabic-folded, reuse the C2c folding util); paginated 25/page
  (orderBy documentId cursor). Row: image thumb, name, shop name, `PriceTag`, stock chip,
  promo/featured badges.
- Row actions: edit (push existing `ProductFormPage` with the product's shopId — fix any
  owner-assumption found in Before-You-Start #2), duplicate (copy doc, name + " (نسخة)",
  promo/featured cleared), soft delete / restore, delete-forever (founder `*` only,
  double-confirm typing the product name).
- **Bulk mode**: long-press/checkbox multi-select →
  - bulk price: dialog (±% with round-half-up via the M12 idiom `(v*bps+5000)~/10000`, or
    ±fixed piasters; preview line "من 2500 → 2750 قرش")
  - bulk stock toggle, bulk promo flag, bulk featured flag
  - bulk move category/subcategory (dependent dropdowns — reuse the M4 form widgets)
  - executed via `WriteBatch` chunks of ≤ 400; progress dialog; ONE summary audit entry
    (`product.bulkUpdate`, after = `{count, change}`).
- Audit actions appended: `product.update`, `product.softDelete`, `product.restore`,
  `product.duplicate`, `product.hardDelete`, `product.bulkUpdate`.
- Bulk image upload / image replacement: replacement = existing form's image picker;
  bulk upload deferred to Session 14 note (media library covers it better).

i18n both ARBs (bulk dialogs, previews, confirms).

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Model test: old product doc parses (no new fields); soft-deleted product excluded
      from customer shop page + search but visible in console with deleted filter.
- [ ] Bulk price +10% on 3 seeded products → each rounds half-up correctly (verify one by
      hand), single audit entry with count 3.
- [ ] Duplicate creates an independent doc; editing the copy doesn't touch the original.
- [ ] Owner flows regression: owner still CRUDs their own catalog exactly as before.
- [ ] Support-role account: products section hidden; direct Firestore product write denied
      by rules.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_09_TAXONOMY_GEO.md
User action: deploy rules + any new indexes.
```
