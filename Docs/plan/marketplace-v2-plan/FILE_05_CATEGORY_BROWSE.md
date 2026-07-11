# SESSION 5 — Category Browse: Chips + Preserved Filter
# Files: lib/presentation/home/pages/customer_home_page.dart, lib/presentation/home/bloc/shops_*.dart, lib/presentation/shop/pages/shop_page.dart (+ its bloc), router

---

## Before You Start

1. Open `customer_home_page.dart` + `shops_bloc.dart`/`shops_event.dart`/`shops_state.dart` — the category chips row already exists. Read exactly how selection is stored and how the shop list filters.
2. Open `shop_page.dart` — read how products load and whether any filter exists today.
3. Open the router — find how home navigates to a shop (what arguments the shop route takes).

Do not write anything yet.

---

## Task A — Chips polish (home)

Against the spec's §6 checklist, fix only what's missing (much may already pass):

- One horizontally scrollable row (`ListView` horizontal / `SingleChildScrollView`), `All`/`الكل` chip first.
- Selected chip visually distinct using existing `AppColors` tokens only; selection change animates with the standard motion scale (no bounce; honour reduced-motion).
- Selection updates the list in place via the existing bloc event — verify no full-page rebuild/flicker (one emit, no double-Loading — Shoppy lesson).
- Selected chip stays selected after scrolling the list and after returning from a shop (bloc state already survives if the bloc is app-lifetime or provided above the route — confirm; if the bloc dies on navigation, lift its provision so state survives).

## Task B — Carry selection into the shop page

- Add the selected category id to the shop route arguments (nullable).
- `shop_page` receives it and sets an initial product filter: show only products whose `category` equals it. Client-side filter over the already-loaded product list is fine (shops are small); no new Firestore query or index.
- Filter UI on shop page: same chip row style, populated from the categories that actually exist in this shop's products, preselected chip = carried category, `All` chip clears it.
- No carried category (direct navigation, favorites, search) → `All` selected, everything shows.
- Empty result (shop has no products in that category) → designed empty state: existing `EmptyState` widget, copy keys `shopCategoryEmptyTitle`/`shopCategoryEmptyBody` → ar: `لا توجد منتجات في هذا القسم` / `جرّب قسمًا آخر أو اعرض الكل`, en: `No products in this category` / `Try another category or show all`.

## Task C — i18n + brand pass

All new strings in both arb files, `flutter gen-l10n`, chip row passes the dukkan-brand feel checklist (calm motion, tokens only, RTL-first).

---

## Smoke Test

- [ ] Home: chips scroll horizontally, `الكل` first, selection highlights + filters instantly, no flicker, no navigation.
- [ ] Select Grocery → open a shop → shop page opens pre-filtered to Grocery with Grocery chip selected.
- [ ] Tap `All` in shop → all products; pick another chip → filters correctly.
- [ ] Back to home → Grocery chip still selected.
- [ ] Shop with zero Grocery products → designed empty state, not blank.
- [ ] Reduced-motion setting on device: no animation jank; gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_06_COLLECTIONS_DATA.md
```
