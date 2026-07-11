# SESSION 4 — Product Form: Dependent Dropdowns
# Files: lib/presentation/catalog/pages/product_form_page.dart, its bloc (if the form has one), app_ar.arb, app_en.arb

---

## Before You Start

1. Open `product_form_page.dart` (11.7K) — find how `category` is input today (free text field? fixed dropdown?) and how the form validates + submits.
2. Confirm the taxonomy repository from Session 3 is in DI and works.
3. Check `presentation/widgets/common/` for an existing dropdown/select primitive — reuse it; build one there only if none exists.

Do not write anything yet.

---

## Task A — Load taxonomy into the form

On form open, load `getTaxonomy()` (through the form's bloc if it has one; otherwise a lightweight `FutureBuilder` is acceptable for a fixed 5-doc read — match the page's existing style). Loading state: existing shimmer primitive; error state: designed retry row (never blank).

## Task B — Category dropdown → filtered subcategory dropdown

- Dropdown 1: categories, localized name (`nameAr`/`nameEn` by locale).
- Dropdown 2: subcategories of the SELECTED category only; disabled until a category is chosen; resets to null when the category changes.
- Editing an existing product: pre-select from the product's `subcategoryId` (derive parent category by scanning the loaded taxonomy — no extra reads).
- Free-text category entry is removed. Existing `category` field on the doc is now WRITTEN automatically = selected subcategory's parent id (keeps home chips + old queries working).
- Search inside dropdowns: taxonomy is ~5×5 — skip search UI for now, note in code comment that `DropdownMenu` with `enableFilter` is the upgrade path if the tree grows. (Spec asks for search "if the list becomes large" — it isn't.)

## Task C — Validation

Form cannot submit without both selections: validator message keys `categoryRequired` / `subcategoryRequired` → ar: `اختر القسم` / `اختر القسم الفرعي`, en: `Choose a category` / `Choose a subcategory`. Confirm the canonical Arabic word for category/subcategory against the brand lexicon before committing (Session 3 added them).

## Task D — Submit path

Ensure the create/update event carries `subcategoryId` + derived `category` through bloc → use case → repository (fields added in Session 3).

---

## Smoke Test

- [ ] Create product: category dropdown lists 5 localized categories; subcategory disabled until category picked; picking Grocery shows only Grocery subcategories.
- [ ] Switching category resets subcategory.
- [ ] Submit without subcategory → inline validation, no crash, nothing written.
- [ ] Edit an existing seeded product → both dropdowns pre-selected correctly.
- [ ] Saved doc in console: `subcategoryId` + matching parent `category`.
- [ ] RTL layout correct; gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_05_CATEGORY_BROWSE.md
```
