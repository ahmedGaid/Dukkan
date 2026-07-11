# SESSION 6 — Shop Collections (Data + Owner CRUD)
# Files: lib/domain/collections/** (new), lib/data/collections/** (new), lib/presentation/catalog/ (collections manager page, new), firestore.rules, router, DI, arb files

---

## Before You Start

1. Open `lib/domain/favorites/` + `lib/data/favorites/` — copy this layer pattern again.
2. Open `catalog_manager_page.dart` — owner's catalog hub; the collections manager will be reached from here.
3. Open `firestore.rules` — read the `/shops` owner-write rule; the subcollection rule mirrors it.

Do not write anything yet.

---

## Task A — Firestore shape

```
/shops/{shopId}/collections/{collectionId}
  nameAr: "عروض"      nameEn: "Offers"     sort: 1     createdAt: <iso>
```

Product side (Session 7 wires the UI): `collectionIds: ["..."]` array on the product doc.

Rules: read = any authed user (customers see collections in the shop page); create/update/delete = shop owner only (same owner check as `/shops/{shopId}` writes). Deleting a collection doc does NOT touch products — stale ids in `collectionIds` are ignored at render time (cheap, no fan-out delete).

## Task B — Entity + repo + datasources

`ShopCollection` entity (id, nameAr, nameEn, sort). Repository: `watch/get(shopId)`, `create`, `rename`, `delete`. Remote datasource + DI registration, favorites-style. No local cache (owner-only management screen, low value offline).

## Task C — Owner collections manager page

New page reachable from `catalog_manager_page.dart` (add an entry row/button "المجموعات" / "Collections"):

- List of collections with product-count-free simple rows (count needs a query per row — skip, keep calm).
- Create: bottom sheet with TWO name fields (Arabic required, English required — parity rule applies to owner content the customer sees).
- Rename: same sheet pre-filled. Delete: confirm dialog — copy must say products are kept: ar `حذف المجموعة لا يحذف المنتجات`, en `Deleting the collection keeps the products`.
- Suggested starter examples as placeholder text (عروض، الأكثر مبيعًا، جديد) — placeholders only, nothing auto-created.
- Empty state designed (`EmptyState` widget): ar `لا توجد مجموعات بعد`, en `No collections yet`.

## Task D — Bloc

`CollectionsBloc` (load/create/rename/delete events). After each mutation update the loaded list in place — no Loading refire (Shoppy lesson). Errors → `AppSnackBar.error`, blame-free copy.

---

## Smoke Test

- [ ] Owner: catalog → Collections → create `عروض`/`Offers` → appears instantly, doc visible in console under the shop.
- [ ] Rename works; list updates without flicker.
- [ ] Delete shows the keeps-products warning; collection gone, products untouched.
- [ ] Second shop owner account cannot see/edit the first shop's collections (rules).
- [ ] Empty state renders before first collection; gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_07_COLLECTIONS_UI.md
```
