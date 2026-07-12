# SESSION 7 — Shop Management: lifecycle, flags, transfer, edit-any
# Files: lib/domain/shop/entities/shop.dart, lib/data/shop/** (model/datasource),
#        firestore.rules, worker/src/admin.js, lib/presentation/console/shops/** (new),
#        lib/presentation/shop/pages/shop_onboarding_page.dart,
#        home/search shop queries (client-side status filter), lib/core/di/injector.dart,
#        lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/domain/shop/entities/shop.dart` + its model — current fields.
2. Find every place shop lists reach customers: home nearby list (ShopsBloc), search
   (SearchBloc), favorites — `grep -r "watchShops\|getShops" lib/` and read the repository.
3. Open `shop_onboarding_page.dart` — where the `/shops` doc is created.
4. Open `firestore.rules` `/shops` block — existing owner-update + rating-bump branches.

Do not write anything yet.

---

## Task A — Shop lifecycle + flag fields (additive)

`Shop` entity/model: add `status` (`'pending'|'active'|'suspended'`, **missing → active**
— every live doc stays valid), `isFeatured` (default false), `isVerified` (default false),
`deleted`/`deletedAt`/`deletedBy` (soft delete, default absent).

Customer-facing filter: everywhere customers receive shops, drop non-active + deleted
**client-side in the repository impl** (Firestore can't express "missing OR active"; shop
counts are small). Owner's own shop + console are exempt.

Onboarding change (behavior change, locked in index): new shops created with
`status: 'pending'`. Owner sees a designed "تحت المراجعة" (under review) banner in the
catalog manager while pending. Existing shops unaffected (missing = active).

## Task B — Rules

`/shops` update: keep both existing branches, add:

```
        || (hasPerm('shops.update')
          && request.resource.data.ownerUid == resource.data.ownerUid)
```

(ownership change stays impossible client-side — that is the Worker's job). Create:
add `|| hasPerm('shops.update')` branch WITHOUT the self-ownerUid condition (console
creates a shop for a named owner). Delete stays `false` (soft only).

## Task C — Worker: ownership transfer

Route `/admin/shops/transfer` (perm shops.transfer): body `{shopId, newOwnerUid}` —
verify new owner's `/users` doc exists with role `owner` (else 400), patch `ownerUid`,
audit with before/after. Note in response if the OLD owner still has `role: owner` but no
shop (console shows a hint; persona role handling stays manual via Session 6).

## Task D — Console shops board

- `/console/shops` (section perm shops.update): status filter chips
  (الكل/قيد المراجعة/نشط/موقوف/محذوف), search by name (Arabic-folded contains on loaded
  page — shops are few), paginated list. Row: logo, name, owner, status chip,
  featured/verified badges, rating.
- Detail page `/console/shops/:id`: everything editable — name ar/en, address, isOpen,
  logo re-upload (existing `/upload` flow), status transitions
  (approve pending→active with confirm; reject pending→suspended with required reason;
  suspend/unsuspend), featured + verified switches, soft delete/restore.
  Products shortcut → `/console/products?shopId=…` (route lands Session 8 — hide until
  then), collections shortcut → existing `CollectionsManagerPage(shopId)` (staff write
  needs a `hasPerm('shops.update')` OR-branch on the nested `/collections` rules — add it).
- Create-shop form (perm shops.update): owner picker (search users by email, role owner),
  then the same fields as onboarding.
- Every mutation: Firestore-direct + `reportAudit` fire-and-forget (`shop.approve`,
  `shop.reject`, `shop.suspend`, `shop.feature`, `shop.verify`, `shop.softDelete`,
  `shop.restore`, `shop.update`) — append to `audit_actions.dart`. Transfer goes through
  the Worker (audited there, `shop.transfer`).
- Dashboard pendingShops tile now counts real pending docs.
- Working hours: add optional `hoursNote` string (ar) shown on the customer shop header
  under the open/closed chip — full per-day schedule is deliberately deferred (note it).

i18n both ARBs. Lexicon rows: Under review → تحت المراجعة · Verified → مُوثّق ·
Featured → مميّز.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Model tests: Shop parses old doc (no new fields) as active/not-featured; new fields
      round-trip.
- [ ] New signup shop → pending → invisible on customer home/search → console approve →
      visible.
- [ ] Suspend an active shop → disappears from customer surfaces; owner still sees catalog
      + review banner logic unaffected.
- [ ] Transfer via wrangler dev: ownerUid flips, audit entry with before/after; client
      attempt to patch ownerUid directly → rules deny.
- [ ] Featured/verified toggles persist + audit entries appear (reported:true).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_08_PRODUCT_ADMIN.md
User action: deploy rules; wrangler deploy.
```
