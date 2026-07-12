# SESSION 1 — RBAC Foundation: roles, permissions, admin profile
# Files: lib/domain/admin/** (new), lib/data/admin/** (new), firestore.rules,
#        lib/presentation/auth/bloc/auth_bloc.dart, lib/core/router/app_router.dart,
#        lib/core/di/injector.dart, lib/presentation/settings/pages/settings_page.dart,
#        lib/dev/seed_demo_data.dart, lib/l10n/app_ar.arb + app_en.arb, Docs/Brand/BRAND.md

---

## Before You Start

1. Open `lib/domain/finance/` + `lib/data/finance/` — this is the vertical pattern to copy
   (entity → repository interface → impl → remote datasource, no cache).
2. Open `lib/domain/config/repositories/platform_config_repository.dart` — the
   memoized-per-session one-shot contract; `AdminRepository` follows it.
3. Open `lib/presentation/auth/bloc/auth_bloc.dart` — find where the signed-in `AppUser` is
   loaded into state (the session-resolution path) — the admin profile loads there too.
4. Open `firestore.rules` — find `isFounder()` (inside `match /orders`) and the top-level
   `isSignedIn()` / `isSelf()` helpers.
5. Open `lib/dev/seed_demo_data.dart` — find how `_seedTaxonomy()` is structured and called.
6. Open `lib/core/config/app_config.dart` — confirm `founderUid` const.

Do not write anything yet.

---

## Task A — Permission constants + domain entities

Create `lib/domain/admin/entities/permissions.dart`:

```dart
/// Single source of truth for permission names. Dotted strings, grouped by
/// area. `all` ('*') is the founder wildcard — checked by [AdminProfile.can]
/// and by the `hasPerm` helper in firestore.rules; keep the three in sync.
class Permissions {
  const Permissions._();

  static const all = '*';

  static const usersRead = 'users.read';
  static const usersCreate = 'users.create';
  static const usersUpdate = 'users.update';
  static const usersDelete = 'users.delete';
  static const adminsManage = 'admins.manage';

  static const shopsUpdate = 'shops.update';
  static const shopsTransfer = 'shops.transfer';
  static const productsCreate = 'products.create';
  static const productsUpdate = 'products.update';
  static const productsDelete = 'products.delete';

  static const ordersRead = 'orders.read';
  static const ordersUpdate = 'orders.update';
  static const ordersForceStatus = 'orders.forceStatus';
  static const ordersAssignDriver = 'orders.assignDriver';

  static const driversManage = 'drivers.manage';
  static const taxonomyEdit = 'taxonomy.edit';
  static const geoEdit = 'geo.edit';
  static const financeRead = 'finance.read';
  static const settingsEdit = 'settings.edit';
  static const notificationsSend = 'notifications.send';
  static const promosEdit = 'promos.edit';
  static const reportsExport = 'reports.export';
  static const imagesDelete = 'images.delete';
  static const auditlogsRead = 'auditlogs.read';
  static const systemTools = 'system.tools';
  static const systemImpersonate = 'system.impersonate';
}
```

Create `lib/domain/admin/entities/staff_role.dart` — enum `StaffRole { support, moderator,
admin, founder }` with `wire` string + `rank` int getter (40/60/80/100) + `fromWire` factory,
mirroring how `lib/domain/auth/entities/user_role.dart` does it.

Create `lib/domain/admin/entities/admin_profile.dart`:

```dart
class AdminProfile extends Equatable {
  const AdminProfile({required this.uid, required this.role,
    required this.permissions, required this.isActive, required this.rank});

  final String uid;
  final StaffRole role;
  final Set<String> permissions; // flat, already denormalized (role + extras)
  final bool isActive;
  final int rank;

  bool can(String perm) =>
      isActive && (permissions.contains(perm) || permissions.contains(Permissions.all));
}
```

(Match the project's Equatable usage — check whether existing entities extend Equatable;
copy their exact style.)

Create `lib/domain/admin/repositories/admin_repository.dart` — interface:
`Future<AdminProfile?> getAdminProfile(String uid)` (null = not staff). Create use case
`lib/domain/admin/usecases/get_admin_profile.dart` following `GetFinanceSummary`'s shape.

## Task B — Data layer

Create `lib/data/admin/models/admin_profile_model.dart` — `fromFirestore(uid, data)` parsing
`role` (string), `permissions` (List→Set, default empty), `isActive` (default false),
`rank` (default 0). Unknown role string → `StaffRole.support` with `isActive: false`
(fail-closed).

Create `lib/data/admin/datasources/admin_remote_datasource.dart` — one `get()` on
`/admins/{uid}`, returns null on missing doc. Create
`lib/data/admin/repositories/admin_repository_impl.dart` — memoized per uid per app session
(same memo shape as `PlatformConfigRepositoryImpl`), with a `void reset()` for logout.

Register all in `lib/core/di/injector.dart` next to the finance registrations
(datasource → repo → use case order).

## Task C — Rules: global helpers + staff read branches

In `firestore.rules`, directly below `isSelf()`, add:

```
    // RBAC (Founder Console session 1). /admins/{uid} carries a FLAT
    // `permissions` array — the Worker denormalizes role permissions + extras
    // into it on every change, so rules do exactly one get() here. hasPerm is
    // deliberately auth-only (never resource.data) so aggregate queries stay
    // legal (M13 lesson).
    function adminDoc() {
      return get(/databases/$(database)/documents/admins/$(request.auth.uid)).data;
    }
    function isStaff() {
      return isSignedIn()
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    function hasPerm(p) {
      return isStaff() && adminDoc().isActive == true
        && adminDoc().permissions.hasAny([p, '*']);
    }
```

Add new collection blocks (before the closing deny-all):

```
    // Staff registry + role definitions — Worker/seed-managed only. A staff
    // member may read their own admin doc (the app loads it at login);
    // admins.manage may read all (user management screens).
    match /admins/{uid} {
      allow read: if isSelf(uid) || hasPerm('admins.manage');
      allow write: if false;
    }
    match /roles/{roleId} {
      allow read: if isStaff();
      allow write: if false;
    }
```

Extend existing reads (keep every existing branch untouched):
- `/orders` read: `allow read: if isFounder() || hasPerm('orders.read') || isOrderOwner() || …`
- `/users` read: `allow read: if isSelf(userId) || hasPerm('users.read');`

## Task D — AuthBloc carries the admin profile

In `auth_bloc.dart`, at the point the authenticated `AppUser` lands in state, also call
`GetAdminProfile` (inject via constructor, wire in `injector.dart`) and store
`AdminProfile? adminProfile` on the auth state (copyWith + props). On sign-out, call the
repository `reset()`. Failure loading the profile → treat as null (not staff), never block
login.

## Task E — Switch the founder gates to permissions

- `app_router.dart` `_redirect`: replace the `/finance` uid check with
  `!(adminProfile?.can(Permissions.financeRead) ?? false)` — keep a
  `|| user?.uid == AppConfig.founderUid` fallback (break-glass until seeding is verified).
- `settings_page.dart`: `_FinanceRow` gate → same combined check.
- Leave `AppConfig.founderUid` in place; update its doc comment: now the break-glass
  bootstrap, primary gate is `/admins`.

## Task F — Seed roles + founder admin

In `seed_demo_data.dart`, add `_seedRbac()` (called like `_seedTaxonomy()`):
- `/roles/founder` `{permissions: ['*'], rank: 100}`; `/roles/admin` (all except
  `admins.manage`, `system.impersonate`, `settings.edit`; rank 80); `/roles/moderator`
  (shops/products/taxonomy/orders read+update; rank 60); `/roles/support`
  (`users.read`, `orders.read`, `orders.update`; rank 40).
- `/admins/{AppConfig.founderUid}` `{role: 'founder', permissions: ['*'], isActive: true,
  rank: 100, createdAt: now}`.
Remember the seed needs the usual temporarily-relax-rules-then-restore pass (same as
`/categories`).

i18n: no new user-visible strings this session except none — if any snackbar/copy added,
both ARBs. Lexicon: add **Permission → صلاحية** row to `Docs/Brand/BRAND.md`.

---

## Smoke Test

- [ ] `flutter analyze` 0 issues; `flutter test` green; parity script passes.
- [ ] New unit tests: `AdminProfileModel.fromFirestore` defaults (missing fields fail closed);
      `AdminProfile.can` (exact perm, wildcard, inactive → false).
- [ ] AuthBloc test: authenticated emit includes adminProfile null for non-staff, profile for staff (fake repo).
- [ ] App still builds and runs; founder account still reaches `/finance`; a customer account
      still bounces off `/finance`.
- [ ] Rules file parses (paste into console rules editor to validate — do NOT publish yet
      if mid-plan; list the changed blocks for the user).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_02_WORKER_ADMIN_API.md
User action: deploy updated firestore.rules; run one seed pass (relax→seed→restore).
```
