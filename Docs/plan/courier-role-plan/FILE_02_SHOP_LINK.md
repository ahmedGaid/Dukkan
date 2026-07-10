# SESSION 2 — Courier ↔ Shop Link (invite code + membership)
# Files: firestore.rules, lib/domain/shop/entities/shop_courier.dart (NEW),
#        lib/domain/shop/repositories/*, lib/domain/shop/usecases/join_shop_as_courier.dart (NEW),
#        lib/domain/shop/usecases/get_shop_couriers.dart (NEW), lib/domain/shop/usecases/remove_shop_courier.dart (NEW),
#        lib/data/shop/** (model + datasource + repo impl), lib/core/di/injector.dart,
#        lib/presentation/courier/pages/join_shop_page.dart (NEW),
#        lib/presentation/shop/pages/shop_couriers_page.dart (NEW), owner shell entry point,
#        lib/l10n/app_ar.arb + app_en.arb, tests

---

## Before You Start

1. Recall `dukkan-flutter` (Clean Architecture layer rules) + `dukkan-brand`.
2. Open `lib/domain/shop/repositories/` → read the shop repository interface; note method style (Either/Failure? plain futures?). **Mirror it exactly.**
3. Open `lib/data/shop/datasources/` → read the Firestore shop datasource: how collections are referenced, how models map docs.
4. Open `lib/core/di/injector.dart` → find where shop usecases are registered.
5. Open the owner shell (`lib/presentation/shell/owner_home_shell.dart`) → find the AppBar/actions area where a "Couriers" entry can live.
6. Open `lib/presentation/shop/pages/shop_onboarding_page.dart` → note form/AppTextField/AppButton usage to copy for the join page.

Do not write anything yet.

---

## Task A — Data shape + rules

Membership lives at `/shops/{shopId}/couriers/{courierUid}` with fields:
`uid` (string, == doc id), `name`, `phone`, `joinedAt` (server timestamp).
The invite code v1 **is the shopId** — owner copies it from the couriers page and sends it over
WhatsApp; courier pastes it in the join page. (Short human codes can come later; don't build them now.)

In `firestore.rules`, inside `match /shops/{shopId} { … }` add a nested block after the existing
rules (before the closing brace of the shops match):

```
// Courier membership (D2): a courier joins a shop by invite code; the doc id
// is the courier's own uid. Owner manages (reads/removes) his shop's couriers.
match /couriers/{courierUid} {
  function isShopOwnerOf() {
    return isSignedIn() &&
      get(/databases/$(database)/documents/shops/$(shopId)).data.ownerUid
        == request.auth.uid;
  }
  function callerIsCourier() {
    return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role
      == 'courier';
  }

  allow read: if isSelf(courierUid) || isShopOwnerOf();

  allow create: if isSelf(courierUid)
    && callerIsCourier()
    && request.resource.data.uid == courierUid
    && request.resource.data.name is string;

  allow update: if false;

  allow delete: if isSelf(courierUid) || isShopOwnerOf();
}
```

Also add a collection-group rule at the top level of `match /databases/{database}/documents`
(next to the other top-level matches) so a courier can list his own memberships across shops:

```
// Courier lists his own memberships across all shops (collectionGroup query).
match /{path=**}/couriers/{courierUid} {
  allow read: if isSelf(courierUid);
}
```

Deploy rules. A `collectionGroup('couriers').where('uid', isEqualTo: uid)` query needs a
collection-group index on `uid` — Firestore will print the exact creation link on first run;
note it in the report if the console step is user-side.

## Task B — Domain layer

Create `lib/domain/shop/entities/shop_courier.dart`: Equatable entity with `uid`, `name`,
`phone`, `joinedAt`. Match `shop.dart` style (doc comment explaining what it is, props list).

Extend the shop repository interface with three methods (mirror existing signature style):
- `joinShopAsCourier(String shopId, ShopCourier courier)` — creates the membership doc; fails with the existing NotFound-style Failure if the shopId doesn't exist.
- `watchShopCouriers(String shopId)` / or `getShopCouriers` — owner side (match how the repo does realtime elsewhere; if S3 order desk uses streams, use a stream here too).
- `removeShopCourier(String shopId, String courierUid)` — owner removes.
- `getCourierShops(String courierUid)` — courier's memberships via collectionGroup (used by session 4's join-state check and by the join page to show "already joined").

Create the matching usecases: `join_shop_as_courier.dart`, `get_shop_couriers.dart`,
`remove_shop_courier.dart` (+ `get_courier_shops.dart`) — one call-through class each, same shape
as existing usecases in `lib/domain/shop/usecases/`.

## Task C — Data layer

Create `ShopCourierModel` in `lib/data/shop/models/` (fromFirestore/toFirestore, `joinedAt` via
`FieldValue.serverTimestamp()` on write). Extend the Firestore shop datasource + repository impl
with the four operations. Join flow: first `get()` the shop doc by the entered code — if it does
not exist, throw/return the repo's standard not-found failure so the UI can show a clear
"كود غير صحيح" error instead of a rules denial.

## Task D — Courier join page

Create `lib/presentation/courier/pages/join_shop_page.dart`:
- AppBar title `l10n.courierJoinShopTitle`.
- One `AppTextField` for the code (`l10n.courierJoinCodeField`), paste-friendly, plus an
  `AppButton` (`l10n.actionJoinShop`) that calls `JoinShopAsCourier` with the signed-in user's
  uid/name/phone from `AuthBloc` state.
- Success → `AppSnackBar` success (`l10n.courierJoinedShop`, includes the shop name) and pop.
  Wrong code → inline error text under the field, blame-free wording.
- Keep state local (StatefulWidget) unless existing pages of this size use a bloc — match the codebase.

Wire it from the session-1 placeholder shell: replace the placeholder `EmptyState` action area
with a button "انضم لدكان" opening this page (add a route `/courier/join` in `app_router.dart`).

## Task E — Owner couriers page

Create `lib/presentation/shop/pages/shop_couriers_page.dart` (route `/shop-couriers`):
- Reachable from the owner shell (add an `IconButton` with `Icons.delivery_dining_outlined` +
  tooltip `l10n.ownerCouriersTitle` in the order-desk AppBar actions, or a tile if the owner
  shell has a settings/menu surface — pick whichever surface already exists; do not invent a new nav pattern).
- Top card: the invite code (the shopId) with a copy button (`Clipboard.setData`) and one line of
  helper copy (`l10n.ownerInviteCodeHint` — "شارك الكود مع المندوب لينضم لدكانك").
- Below: realtime list of `ShopCourier`s (name, phone, joined date) with a remove action
  (confirm dialog before delete — destructive).
- Designed empty state: "لا مناديب بعد" + the invite-code card still visible.

## Task F — i18n + DI + tests

New keys (ar + en, keep parity): `courierJoinShopTitle`, `courierJoinCodeField`,
`actionJoinShop`, `courierJoinedShop`, `courierJoinBadCode`, `ownerCouriersTitle`,
`ownerInviteCodeHint`, `ownerInviteCodeCopied`, `ownerNoCouriersTitle`, `ownerNoCouriersBody`,
`actionRemoveCourier`, `confirmRemoveCourier`. Run `flutter gen-l10n`.

Register the new usecases/repo methods in `injector.dart` following the existing pattern.

Tests: repo impl join/remove happy path + bad-code failure (mock datasource, same style as
existing data-layer tests); usecase call-through tests.

---

## Smoke Test

- [ ] Gates green (analyze / test / parity).
- [ ] Owner account → couriers page shows invite code; copy button works (snackbar).
- [ ] Courier account → join page; paste code → success snackbar; membership doc appears at `/shops/{shopId}/couriers/{uid}` with correct name/phone.
- [ ] Wrong code → clear Arabic error, no crash, no rules-denial red screen.
- [ ] Owner sees the courier in the list in realtime; remove works after confirm; list empties back to designed empty state.
- [ ] A customer account can NOT create a membership doc (rules reject — verify in rules playground or by expecting the join page to be unreachable for customers).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, mark D2, commit + push
→ Clear session, then open FILE_03_ORDER_ASSIGNMENT.md and continue
```
