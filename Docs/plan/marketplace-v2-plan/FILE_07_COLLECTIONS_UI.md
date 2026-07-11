# SESSION 7 — Collections: Product Assignment + Customer View
# Files: lib/domain/product/entities/product.dart (+model/datasource), product_form_page.dart, lib/presentation/shop/pages/shop_page.dart, arb files

---

## Before You Start

1. Re-open `product.dart` + model — you are adding `collectionIds` next to Session 3's `subcategoryId`.
2. Open `product_form_page.dart` — find where the Session 4 dropdowns landed; collections picker goes below them.
3. Open `shop_page.dart` — note where the Session 5 category chip row landed; the collections row goes near it.

Do not write anything yet.

---

## Task A — `collectionIds` on Product

Entity: `final List<String> collectionIds;` default `const []` (old docs parse fine). Model serialize/parse null-safe. Datasource create/update passes it through. Props updated.

## Task B — Picker in product form

Below the subcategory dropdown: multi-select chips of the shop's collections (loaded via Session 6 repo). Optional — zero selected is valid. Label key `productCollections` → ar `المجموعات (اختياري)`, en `Collections (optional)`. Shop with no collections → hide the block entirely (not an empty shell).

## Task C — Customer shop page

Two additions, both calm:

- **Collection filter chips**: a second small chip row (or merged segment under the category row — pick whichever reads quieter with the existing layout; brand checklist decides) listing this shop's collections; tapping filters the product grid client-side to products whose `collectionIds` contains it. Combines with the category filter (AND).
- **Stale-id safety**: product referencing a deleted collection simply matches nothing — verify no crash.

## Task D — Brand + i18n pass

New strings in both arbs, `gen-l10n`, run the dukkan-brand feel checklist on the shop page (two chip rows must not read noisy — if they do, collapse collections into a single "filter" affordance and note the decision in the commit).

---

## Smoke Test

- [ ] Owner assigns a product to `عروض` + one more collection → doc shows both ids.
- [ ] Customer shop page: tapping the collection chip filters correctly; combined with a category chip filters to the intersection.
- [ ] Delete the collection as owner → customer page: chip gone, products still listed, no crash.
- [ ] Product form in a shop with no collections shows no collections block.
- [ ] Gates green + brand checklist passed.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_08_AREAS_DRIVERS.md
```
