# SESSION 15 — Impersonation + Developer Tools
# Files: worker/src/admin.js, lib/main.dart (banner host), lib/presentation/auth/bloc/auth_bloc.dart,
#        lib/presentation/console/users/ (impersonate action), lib/presentation/console/devtools/** (new),
#        lib/dev/seed_demo_data.dart → lib/dev/seed.dart (refactor),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `worker/src/admin.js` + `firebase.js` — `SignJWT` usage in
   `getServiceAccountToken` (the custom-token mint uses the same key/lib).
2. Open `lib/main.dart` — the `MaterialApp`/router `builder` (banner wraps here).
3. Open `lib/dev/seed_demo_data.dart` — entrypoint structure (what `main()` does vs the
   seed functions).
4. Open Session 6's user detail page — where the impersonate action lands.

Do not write anything yet.

---

## Task A — Worker `/admin/impersonate`

Perm `system.impersonate` (founder-only in the default role seeds). Body `{targetUid}`.
1. Load `/admins/{targetUid}` — if it exists and `rank >= caller.rank` → 403 (never
   impersonate a peer/superior; covers founder).
2. Mint TWO Firebase custom tokens (RS256 `SignJWT` with the service-account key):
   - target: `{iss/sub: sa.client_email, aud:
     'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
     iat, exp: iat+3600, uid: targetUid, claims: {impersonatedBy: callerUid}}`
   - returnToken: same but `uid: callerUid`, no claims.
3. Audit `impersonation.start` (targetType user, targetId targetUid) BEFORE returning.
4. Return `{token, returnToken}`.

## Task B — App impersonation flow

- `ImpersonationSession` singleton (registered in DI): holds `returnToken` + original
  founder name in memory only (never persisted).
- User detail page action «الدخول كهذا المستخدم» (visible when
  `adminProfile.can(systemImpersonate)`, confirm dialog explains logging): call endpoint →
  store returnToken → `FirebaseAuth.instance.signInWithCustomToken(token)` — AuthBloc's
  existing auth-state listener rebuilds the app as the target (router redirect does the
  rest: customer→home, owner→home, courier→courier).
- **Banner**: in `main.dart`'s app `builder`, wrap the child with an
  `ImpersonationOverlay` that watches AuthBloc; on each authenticated user it checks
  `getIdTokenResult().claims['impersonatedBy']` (cache the check per uid). When present:
  persistent top strip (warning container color, «وضع الانتحال: {name} — جلسة مسجّلة»)
  with an exit button. The strip renders ABOVE every screen incl. dialogs' barrier
  (Overlay/Stack at the builder level — verify it survives route changes).
- Exit: `signInWithCustomToken(returnToken)`; on ANY failure (expired >1 h, revoked) →
  `signOut()` → login screen (fail-safe, never stuck-as-user). After returning, fire
  `reportAudit('impersonation.end', targetId: impersonatedUid)`.
- Sanity guard: while impersonating, `/console` guard already blocks (target isn't staff);
  verify no cached admin state leaks (AdminRepository.reset() on every auth user change —
  confirm Session 1 wired it to CHANGE, not just sign-out).

## Task C — Developer tools page

`/console/devtools` (section perm system.tools):
- **Environment card**: app version + buildNumber (`AppConfig`), projectId
  (`firebase_options`), workerBaseUrl + `workerConfigured`, flavor (kDebugMode/release).
- **Health checks** (run-all button, per-row pass/fail + latency): Worker `/admin/ping`,
  Firestore read (`/config/platform` get), config sanity (fields non-null, driverShare ≤
  deliveryFee), taxonomy non-empty, areas non-empty, active-driver exists.
- **Seed**: refactor `lib/dev/seed_demo_data.dart` — extract everything into
  `lib/dev/seed.dart` exposing `Future<void> runSeed(FirebaseFirestore db, {bool rbac,
  bool catalog, …})`; the old entrypoint becomes a thin `main()` calling it (CLI path
  unchanged). Console button «إعادة تعبئة البيانات التجريبية» behind a type-«SEED»-to-confirm
  dialog; visible only to `*` (founder) AND when project is the dev project — guard by
  projectId allowlist const.
- **Fake data**: generate N fake customers (create `/users` docs only — no Auth accounts;
  labeled fake, `fake: true` field) / fake orders against a chosen shop (random items from
  its products, random recent createdAt, statusHistory consistent) — small generators in
  `lib/dev/fakes.dart`; cleanup button deletes `fake == true` docs.
- **Caches**: clear local cache datasources (taxonomy/areas/shops/products local caches —
  Before You Start: check each local datasource for a `clear()`; add where missing) +
  `PlatformConfigRepository.refresh()`.
- **Test notification**: `/admin/notify/user` to own uid («إشعار تجريبي»).
- **Migrations**: `lib/dev/migrations/` registry `List<Migration>` (`id`, `description`,
  `run(db)`), devtools lists them with run buttons + `/config/migrations` doc recording
  applied ids. Ship ONE example: `001_backfill_shops_status` (missing status → 'active').
- Every tool run → `reportAudit` (`devtools.<tool>`).

i18n both ARBs. Lexicon rows: Impersonation → وضع الانتحال · Developer tools → أدوات المطوّر.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Founder impersonates a CUSTOMER: app becomes their session, banner visible on home,
      cart, settings; places nothing; exit returns to founder (console reachable again);
      TWO audit entries (start Worker-side, end reported).
- [ ] Impersonating an admin as admin-rank → 403; as founder → works.
- [ ] Kill the app mid-impersonation → relaunch resolves as the TARGET with banner still
      shown (claim survives) and exit → login screen fallback works when returnToken lost.
- [ ] Health checks all green on the dev env; unplug network → rows fail gracefully.
- [ ] Fake orders generate + cleanup removes exactly the `fake:true` docs.
- [ ] Migration 001 marks applied and is idempotent (second run = no-op).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_16_PROMOTIONS.md
User action: wrangler deploy.
```
