# SESSION 14 — Media Library: R2 browser, orphan finder, storage stats
# Files: worker/src/admin.js, worker/src/index.js (ALLOWED_FOLDERS),
#        lib/domain/media/** (new), lib/data/media/** (new),
#        lib/presentation/console/media/** (new), lib/core/di/injector.dart,
#        lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `worker/src/index.js` — `handleUpload` (key scheme: `{folder}/{uid}/{uuid}.{ext}`)
   + `ALLOWED_FOLDERS`.
2. R2 bucket binding is `env.BUCKET` — list API: `env.BUCKET.list({prefix, cursor, limit})`
   returns `{objects: [{key, size, uploaded}], truncated, cursor}`.
3. Open `lib/data/storage/` (S1a) — the upload datasource the "replace" flow reuses.
4. Note every Firestore field that holds an image URL: `shops.logoUrl`,
   `products.imageUrl`, `drivers.idDocUrl` (S11), `banners.imageUrl` (S16 — future).

Do not write anything yet.

---

## Task A — Worker media endpoints

| Route | Perm | Does |
|---|---|---|
| `/admin/media/list` | images.delete *(read rides the delete perm — media is one console area)* | body `{prefix?, cursor?}` → `env.BUCKET.list({prefix, cursor, limit: 100})` → `{objects: [{key, size, uploaded}], cursor?}` |
| `/admin/media/stats` | images.delete | full list pagination loop server-side → `{count, totalBytes, byFolder: {folder: {count, bytes}}}`. Cap at 10k objects, return `truncated: true` beyond (bucket is small; honest cap) |
| `/admin/media/delete` | images.delete | body `{keys: [≤100]}` → `env.BUCKET.delete(keys)` + ONE audit entry (`media.delete`, after = `{count, keys(first 20)}`) |

Also add `'banners'` to `ALLOWED_FOLDERS` now (Session 16 needs it; one deploy instead
of two).

## Task B — Flutter vertical

`MediaObject` entity `{key, size, uploaded, url}` (url = `PUBLIC_BASE_URL` + key — the
Worker returns keys; datasource composes URLs the same way `/upload` responses do).
`MediaRepository`: `list({folder?, cursor?})`, `stats()`, `delete(keys)` — all via
`AdminApiDataSource`. Use cases per call.

## Task C — Console media page

`/console/media` (section perm images.delete):
- Folder chips (الكل / شعارات الدكاكين / صور المنتجات / مستندات المناديب / بانرات) →
  prefix filter; grid of thumbnails (`ShimmerImage` reuse) with size caption; paginate on
  scroll (cursor).
- Multi-select → bulk delete with confirm dialog («سيتم الحذف نهائيًا — الصور لا تخضع
  للاسترجاع», the ONE hard-delete surface in the app besides founder product
  delete-forever).
- Stats header card: total count + human size + per-folder bars (from `/admin/media/stats`).
- **Unused finder** tab: fetch all referenced URLs (shops.logoUrl + products.imageUrl incl.
  soft-deleted + drivers.idDocUrl + banners when they exist) — set-difference against the
  full key list → grid of orphans with select-all-delete. **Broken finder**: referenced
  URLs whose key is NOT in R2 → list with the owning doc linked (fix = re-upload from the
  owning screen). Both computed client-side; show doc/object counts while loading.
- Upload button (folder-scoped, reuses `/upload`) — completes the "bulk image upload"
  spec item at library level; per-product replacement stays on the product form.
- Crop/compress: NOT built (needs a new dep — locked deferral; note in page code comment).

Audit: `media.delete` (Worker-side). Append to `audit_actions.dart`.

i18n both ARBs. Lexicon row: Media library → مكتبة الصور.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] wrangler dev: list returns seeded objects; delete removes from R2 (verify by URL
      404) + audit entry.
- [ ] Stats totals match Cloudflare dash (one manual cross-check — the last time you
      should ever need that dash).
- [ ] Unused finder: upload an image, reference nothing → appears as orphan; a product's
      real image does NOT.
- [ ] Broken finder: hand-edit a product to a bogus URL (test env) → flagged with doc link.
- [ ] Bulk delete of 3 orphans works; referenced images untouched.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_15_IMPERSONATION_DEVTOOLS.md
User action: wrangler deploy.
```
