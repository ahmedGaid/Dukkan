# SESSION 3 — Global Taxonomy (Data Layer)
# Files: lib/domain/taxonomy/** (new), lib/data/taxonomy/** (new), lib/domain/product/entities/product.dart, product model/datasource, lib/dev/seed_demo_data.dart, firestore.rules, lib/core/di

---

## Before You Start

1. Open `lib/domain/product/entities/product.dart` — note existing `category` (String) field. It STAYS (backward compat + shop-level chips currently rely on it).
2. Open `lib/dev/seed_demo_data.dart` — find how the 53 products get their `category` value and what the shop-level category values are (Grocery/Drinks/... wire strings).
3. Open `firestore.rules` — note the read-rule style for public collections (`/shops`, `/products`).
4. Open an existing simple feature for the layer pattern to copy: `lib/domain/favorites/` + `lib/data/favorites/`.

Do not write anything yet.

---

## Task A — Firestore shape (seed-managed, read-only to clients)

One doc per category in `/categories`, subcategories embedded (taxonomy is small + fixed — one read loads all; no join queries needed):

```
/categories/{categoryId}
  nameAr: "بقالة"        nameEn: "Grocery"      sort: 1
  subcategories: [
    { id: "fruits",     nameAr: "فواكه",  nameEn: "Fruits" },
    { id: "vegetables", nameAr: "خضروات", nameEn: "Vegetables" },
    { id: "rice",       nameAr: "أرز",    nameEn: "Rice" },
  ]
```

Rules: `allow read: if request.auth != null; allow write: if false;` — founder edits via console/seed only.

## Task B — Seed the fixed taxonomy

In `seed_demo_data.dart`, add a `_seedTaxonomy()` step writing the full v1 tree (align top-level ids with the existing shop-category wire strings found in reading step 2 so home chips keep matching):

- Grocery (بقالة): fruits/فواكه, vegetables/خضروات, rice/أرز, pasta/مكرونة, oils/زيوت
- Drinks (مشروبات): juice/عصير, water/مياه, soda/مشروبات غازية
- Bakery (مخبوزات): bread/خبز, pastry/فطائر
- Snacks (سناكس): chips/شيبسي, sweets/حلويات, biscuits/بسكويت
- Dairy (ألبان): milk/لبن, cheese/جبن, yogurt/زبادي

Arabic words: check `Docs/Brand/BRAND.md` lexicon first — if a term exists there, use it; if not, add it there in the same commit (one canonical word per concept).

## Task C — Entities + repository (copy favorites pattern)

`lib/domain/taxonomy/entities/category.dart` + `subcategory.dart` (Equatable, ids + both names), `repositories/taxonomy_repository.dart` with a single `Future<List<Category>> getTaxonomy()`. Data side: model + remote datasource (one `get()` of `/categories` ordered by `sort`) + local cache datasource (`shared_preferences`, same online→remote/offline→cache convention as favorites) + repository impl. Register in DI following the existing order (datasources → repo → use case).

## Task D — `subcategoryId` on Product

- Entity: add `final String? subcategoryId;` (nullable — 53 existing products lack it), add to constructor + props.
- Model: serialize/parse with null-safe default.
- Seed: assign a sensible `subcategoryId` to every seeded product; keep `category` in sync with the subcategory's parent id.
- Datasource create/update: pass the field through.

## Task E — Backfill note

Live DB re-seed covers demo data (`flutter run -t lib/dev/seed_demo_data.dart -d R5CNC0NK6ZT`). No production users yet → no migration script needed. Record that in the commit message.

---

## Smoke Test

- [ ] Re-seed on device → Firestore console shows `/categories` docs with embedded subcategories; every product doc has `subcategoryId`.
- [ ] App still boots: home, shop page, catalog manager all render (nullable field breaks nothing).
- [ ] `getTaxonomy()` returns 5 categories in sort order (verify via a temporary test or debug print in a widget — remove after).
- [ ] Unit test added: taxonomy model parse round-trip + product parses with and without `subcategoryId`.
- [ ] Gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_04_PRODUCT_FORM_DROPDOWNS.md
```
