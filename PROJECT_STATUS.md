# Dukkan (دكان) — Project Status

![Status](https://img.shields.io/badge/status-active--development-brightgreen)
![Progress](https://img.shields.io/badge/progress-86%25-blue)
![Stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Firebase-informational)

> **Last Updated:** 2026-07-13 · **Updated By:** agent · **Branch analyzed:** feat/c2c-search
> 🤖 **AI agents:** read [Executive Summary](#executive-summary) +
> [AI Agent Quick Context](#ai-agent-quick-context) first — 2 minutes gets you 90% of the picture.

## Executive Summary

Two-sided grocery marketplace app for Egypt: customers order from neighborhood shops (دكاكين),
shop owners manage catalog/orders, drivers (مندوبين) deliver. One Flutter app, three public roles
plus a staff console, Arabic-first RTL. Clean Architecture + BLoC + Firebase
(Auth/Firestore/Storage/FCM), COD-only v1. Phases 1–6 (Foundation → Customer core → Owner core →
Polish → Release prep → Marketplace V2) are **code-complete** as of M14 (2026-07-12). **Phase 7
Founder Console** (18-session back-office plan) is in progress: FC1–FC6 code-complete
(2026-07-13) — RBAC, Worker admin API, `/console` shell, audit log viewer, live dashboard, user
management. Gates green (analyze 0, tests 181/181, i18n parity 378). `firestore.rules` +
`firestore.indexes.json` are now **deployed** to `dukkan-93042` (this session); the Cloudflare
Worker deploy is still owed (user); full on-device E2E (R0) still owed before Phase 7
acceptance + release.

## AI Agent Quick Context

- **Current goal:** FC7 — shop management (`Docs/plan/founder-console-plan/FILE_07_SHOP_MANAGEMENT.md`).
- **Architecture:** Flutter + Firebase, Clean Architecture (domain/data/presentation) + BLoC + get_it + go_router; Cloudflare Worker for R2 upload, push relay, and `/admin/*` API.
- **Hard constraints:** money = integer piasters only (never `double`); Arabic/RTL-first, i18n ar/en parity is build-blocking; tokens only via `AppColors`/theme, no raw hex; no new deps without asking; Firebase real from day 1 (no mocks).
- **Key conventions:** one Arabic word per concept (lexicon in `Docs/Brand/BRAND.md`); domain never imports data (audit/users repos keep Firestore types out of domain via value cursors); every empty/error/loading state is designed, never bare; every privileged mutation goes through the Worker (never a direct client Firestore/Auth write), which permission-checks + audits it.
- **Do NOT:** touch `firestore.rules`/Worker deploys without telling the user; don't reintroduce `double` for money; don't add socket-based connectivity checks (Shoppy lesson — use HTTP probe, `lib/core/network/network_info.dart`); don't use `WriteBatch` in the seed script (on-device SDK quirk — individual `.set()` with retry only); don't reuse the memoized `AdminRepository.getAdminProfile` for viewing another uid's staff profile — use `getAdminProfileForUid` (unmemoized) instead, or you'll corrupt the signed-in session's RBAC cache.
- **Current priorities:** (1) FC7 shop management, (2) re-seed full demo data (7 shops/53 products/RBAC/orders — needs a temporary rules relax, see Known Issues), (3) deploy the Cloudflare Worker; Phase 6 R0 full E2E runs once at the end, before release.
- **How to continue safely:** recall `dukkan-resume` skill (reads `dukkan-status` + `Docs/plan/dukkan-roadmap.md`) before picking work; for Phase 7 load `Docs/plan/founder-console-plan/FILE_00_INDEX.md` then one FILE_NN per session; run gates (`flutter analyze`, `flutter test`, `dart run scripts/check_i18n_parity.dart`) before "done".
- **Likely next files to edit:** `lib/presentation/console/shops/` (new, mirrors `console/users/`), `lib/domain/admin/` (extend), `worker/src/admin.js` (add shop routes), `firestore.rules` (`/shops` admin branch).
- **Deeper truth lives in:** `Docs/plan/dukkan-roadmap.md` (phase/session authority), `dukkan-status` skill (live NEXT ACTION/blockers), `Docs/plan/founder-console-plan/FILE_00_INDEX.md` (Phase 7 session detail), `Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md` (Phase 5 detail), `Docs/Brand/BRAND.md` (brand + lexicon), `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` (hard-won lessons).

## What Is This Project?

Dukkan is a two-sided grocery marketplace for Egypt: customers browse nearby shops and order
groceries; shop owners list products and manage incoming orders; drivers (added in Marketplace
V2) deliver assigned orders; staff/founder manage the platform from an in-app Founder Console
(added in Phase 7). UI/UX inspiration is the Ben Soliman app (Arabic retail ordering: promo
carousel, category grid, product cards with inline add-to-cart, order-tracking stepper).
Brand aim: "your neighborhood shop, in your pocket" — premium, minimal, distinctly Dukkan, not a
generic marketplace clone.

**Maturity:** beta — customer/owner/courier features code-complete with 181/181 unit/widget tests
passing; Founder Console 6/18 sessions in; blocked on device-side verification, the Worker deploy,
and store release steps.

## Progress Overview

> ⚠️ Percentages are **estimates** inferred from roadmap position, code, and tests.

| Area | Progress | Status |
|---|---|---|
| **Overall** | `████████░░ 86%` | Phases 1–6 code-complete; Phase 7 at FC6/18; device regression + release ops remain |
| Mobile (Flutter app) | `█████████░ 95%` | Customer, owner, courier flows all built; console shell + user management live |
| Admin Panel (Founder Console) | `███░░░░░░░ 33%` | FC1–FC6 of 18 sessions: RBAC, admin API, shell, audit log, dashboard, user management |
| Backend (Firebase) | `█████████░ 90%` | Auth/Firestore/FCM wired; RBAC/audit/users rules + indexes DEPLOYED (one FC6 rule branch pending redeploy, low-risk) |
| Storage/API (Cloudflare Worker) | `███████░░░ 75%` | Upload + push relay + `/admin/*` (ping/audit/users/admins) coded; user must deploy |
| Authentication | `██████████ 100%` | Email/password + role signup, auth-guarded router, staff RBAC layer |
| Database (Firestore) | `█████████░ 90%` | Schema stable incl. `/admins /roles /auditLogs`; rules + composite indexes deployed |
| Testing | `████████░░ 80%` | 181/181 unit/widget/bloc tests green; zero on-device E2E yet (R0 pending) |
| i18n (ar/en) | `██████████ 100%` | Parity script enforced, 378 keys, build-blocking |
| Release/Deployment | `████░░░░░░ 40%` | Icon/splash done; keystore, screenshots, Play upload, live Crashlytics check pending (user/device side) |
| Documentation | `█████████░ 90%` | Roadmap, brand, plan files (incl. founder-console 18-session plan), status skill all current |

## Architecture & Stack

**Stack:** Flutter (Dart SDK ^3.12.2), Firebase (`firebase_core` 4.11, `firebase_auth` 6.5,
`cloud_firestore` 6.6, `firebase_messaging` 16.0, `firebase_crashlytics` 5.0), `flutter_bloc` 9.1,
`go_router` 17.3, `get_it` 9.2, `equatable`, `intl`, `shared_preferences`, `image_picker`. No
backend server except a Cloudflare Worker (`worker/`) for R2 image upload, FCM push relay, and
the permission-checked `/admin/*` API.

- Clean Architecture: `domain/` (entities, repositories interfaces, usecases) never imports `data/`.
- State management: BLoC per feature vertical (auth, cart, orders, favorites, catalog, driver, finance, audit, dashboard…).
- Money: integer piasters everywhere on the wire and in Firestore; formatted only at UI edge (`lib/core/money.dart`).
- Connectivity: HTTP probe (`NetworkInfo`), not socket-based checkers (Shoppy lesson).
- Realtime: Firestore snapshots for orders/collections/deliveries; local cache datasources for offline read; console repos deliberately no-cache.
- i18n: ARB files (`lib/l10n/`) with a parity-check script, RTL-first `MaterialApp`.
- Image storage: Cloudflare Worker verifies Firebase ID token → R2 put (app never holds R2 keys).
- Founder Console: `/console` ShellRoute (desktop-first NavigationRail/Drawer), per-section permission guard, dashboard uses Firestore aggregate `count()`/`sum()` (no doc downloads).
- Every privileged console mutation is Worker-routed (`/admin/*`) — never a direct client Firestore/Auth write — so it's permission-checked server-side and written to the immutable audit trail in one place. Auth admin ops (suspend/ban/email-change/create/lookup) go through Identity Toolkit REST calls (`worker/src/firebase.js`'s `identityToolkitCall`), authenticated as the service account.

### Folder Structure

```
lib/
  core/           theme tokens (AppColors/Spacing/Radius/Typography), money, network, router, search
  domain/         entities + repository interfaces + usecases, per vertical (auth, shop, product,
                  order, cart, favorites, storage, taxonomy, areas, driver, config, finance,
                  collections, admin, audit, dashboard)
  data/           Firestore/local datasources + repository impls, mirrors domain verticals
  presentation/   pages + BLoCs per feature (auth, home, shop, catalog, cart, orders, favorites,
                  search, settings, driver, finance, console/) + shared widgets/common
  l10n/           ar.json / en.json ARB source + generated
  dev/            seed_demo_data.dart (on-device demo seeding entrypoint)
worker/           Cloudflare Worker — R2 upload, FCM push relay ("/notify"), /admin/* API
                  (src/{index,firebase,admin}.js — perm middleware + audit writer)
scripts/          check_i18n_parity.dart
test/             unit + widget + bloc tests (181 tests)
Docs/
  plan/           dukkan-roadmap.md (authority) + marketplace-v2-plan/ (M1-M14)
                  + founder-console-plan/ (FC FILE_00-FILE_18)
  Brand/          BRAND.md (tokens, voice, Arabic lexicon)
  legacy/         SHOPPY_PROJECT_KNOWLEDGE.md (architecture ancestor + fixed bugs)
  testing/        E2E_MASTER_PROMPT.md + e2e-reports/
```

### Main Modules

- `lib/domain/*` / `lib/data/*` — one vertical per concept: auth, shop, product, order, cart,
  favorites, storage, taxonomy, areas, driver, config, finance, collections, admin (RBAC),
  audit, dashboard.
- `lib/presentation/*` — one folder per feature with `bloc/`, `pages/`, `widgets/`;
  `console/` holds the Founder Console shell, dashboard, audit viewer, user management, shared `stat_tile.dart`.
- `worker/` — standalone Cloudflare Worker, deployed separately from the Flutter app.

### Central Files (handle with care)

| File | Why it matters | Safe to edit casually? |
|---|---|---|
| `firestore.rules` | Security rules — RBAC/audit/FC6 users branch DEPLOYED to `dukkan-93042` (2026-07-13); one narrow FC6 `/users` branch added after that deploy still owed a redeploy (low-risk, Worker bypasses rules for all its own writes) | ⚠️ No |
| `firestore.indexes.json` | Composite indexes DEPLOYED (auditLogs ×4 + orders status+createdAt) | ⚠️ No |
| `lib/core/money.dart` | Integer-piaster money math, round-half-up commission calc | ⚠️ No |
| `Docs/plan/dukkan-roadmap.md` | Single "what next" authority — read before picking any task | ⚠️ No (roadmap edits are session-gated) |
| `Docs/Brand/BRAND.md` | Arabic lexicon — one word per concept, must stay in sync with strings | ⚠️ No |
| `pubspec.yaml` | No new deps without asking | ⚠️ No |

## Features

### ✅ Completed
- [x] Foundation — scaffold, theme, i18n, Firebase auth + roles (F1–F3)
- [x] Customer core — browse (home/shop/search), cart/checkout, orders with realtime status (C1–C4)
- [x] Shop owner core — onboarding, catalog CRUD, order desk (S1–S3)
- [x] Polish — favorites, promos, settings/dark-mode, FCM notifications, ratings (P1–P3)
- [x] Release prep — launcher icon + splash (official pack), Crashlytics wired, signing config wired (R1b, part of R1/R2)
- [x] Marketplace V2 — order details/timeline, global taxonomy, shop collections, driver pool (areas/assignment/courier shell/push), commission ledger + founder finance page (M1–M13)
- [x] M14 code-only acceptance pass — gates green, lexicon/enum audit, E2E prompt updated
- [x] `orderDelivered` push — owner notified when the courier marks an order delivered (2026-07-12)
- [x] Founder Console FC1–FC5 — RBAC foundation (`/admins`+`/roles`, Permissions/StaffRole/AdminProfile), Worker `/admin/*` API (perm middleware + audit writer), `/console` shell (admin guard, desktop-first nav), audit log vertical (immutable `/auditLogs`, filtered/paginated viewer, before/after diff sheet), live dashboard (aggregate stat tiles, 7-day chart, recent activity)
- [x] Founder Console FC6 — user management: Worker `/admin/users/*` (suspend/ban/reactivate, persona role, email change, soft-delete/restore, create, Auth lookup) + `/admin/admins/*` (rank-guarded staff set/remove), `/console/users` list (search/filter/bulk suspend) + `/console/users/:uid` detail (profile, actions, auth/staff cards, shop/orders/audit sections)

### 🟡 Partially Complete
- [ ] Phase 7 Founder Console — 6/18 sessions done; next: FC7 shop management
- [ ] R1 — Store prep: icon/splash/listing copy done; screenshots + feature graphic blocked on seeded device run
- [ ] R2 — Ship: Crashlytics + signing wired; user still needs keystore, on-device Crashlytics check, Play internal-track upload
- [ ] R0 — full on-device acceptance + E2E regression not yet run (deferred to end of plan, before release)
- [ ] Demo data seed — script hardened (individual writes + retry), but full re-seed (7 shops/53 products/RBAC/orders) needs a temporary rules relax pass (see Known Issues)

### ⬜ Not Started
- [ ] Founder Console FC7–FC18 (shop management, products, taxonomy/geo, orders desk, drivers, settings, notifications, media, promotions, search/reports, impersonation, acceptance …)
- [ ] Phone OTP auth (deferred — costs money, v1 uses email+password)
- [ ] Maps-based address entry (deferred — v1 uses manual address entry)

## Roadmap & Next Steps

Full authority: [`Docs/plan/dukkan-roadmap.md`](Docs/plan/dukkan-roadmap.md). Phase 7 session
detail: `Docs/plan/founder-console-plan/FILE_00_INDEX.md`. Marketplace V2 detail:
`Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md`.

**High Priority**
1. FC7 — shop management (`Docs/plan/founder-console-plan/FILE_07_SHOP_MANAGEMENT.md`)
2. Re-seed full demo data on device (needs one temporary relaxed-rules pass, then restore real rules — see `dukkan-status` skill)
3. USER: deploy the Cloudflare Worker (image upload + `/notify` + `/admin/*`)

**Medium Priority**
1. Redeploy `firestore.rules` to pick up FC6's narrow `/users` branch (optional, low-risk — not blocking, Worker bypasses rules for its own writes)
2. R1 screenshots + feature graphic (needs seeded device run)
3. R2 remainder — keystore generation, on-device Crashlytics live-event check, Play internal-track upload

**Low Priority**
1. Phase 6 R0 full E2E regression — runs once at the very end, before Phase 7 acceptance/release
2. iOS build (assets already staged in `Dukkan Logo Assets/iOS/`)

**Current blockers:**
1. USER must deploy the Cloudflare Worker (`worker/README.md`) — blocks live push/upload and any `/admin/*` endpoint actually reaching production (the code is ready; nothing is live until this deploy runs).

## Recent Work

- 2026-07-13 — feat(founder-console): FC6 user management — Worker `/admin/users/*` + `/admin/admins/*`, `/console/users` list + detail (uncommitted at analysis time)
- 2026-07-13 — ops: deployed `firestore.rules` + `firestore.indexes.json` to `dukkan-93042` (clears the long-standing rules/indexes blocker)
- 2026-07-13 — feat(founder-console): FC5 live dashboard — aggregate stat tiles, 7-day chart, recent activity (`62c2eae`)
- 2026-07-13 — feat(founder-console): FC4 Audit Log vertical — rules, indexes, /console/audit viewer (`ac3a9e6`)
- 2026-07-13 — chore(seed): wait for Firestore auth propagation in dev seed script (`412aeab`)
- 2026-07-13 — feat(founder-console): FC3 console shell — /console subtree, admin guard, desktop-first nav (`904c782`)
- 2026-07-12 — feat(founder-console): FC2 Worker admin API — perm middleware, audit writer, first endpoints (`0760771`)
- 2026-07-12 — feat(founder-console): FC1 RBAC foundation — roles, permissions, admin profile (`0e320b4`)
- 2026-07-12 — docs(dukkan): Phase 7 founder-console plan — 18-session back-office roadmap (`2d78a2e`)
- 2026-07-12 — feat(marketplace-v2): orderDelivered push — owner notified on courier delivery (`e3987cc`)
- 2026-07-12 — chore: add brand product/shop images, run_dukkan.vbs; ignore local run logs (`6968d12`)
- 2026-07-12 — docs(dukkan): M14 acceptance — code-only verification pass (`21c5115`)
- earlier: Marketplace V2 M1–M13 (2026-07-11 → 07-12), release prep R1b/R2, Phases 1–4.

**Recent architectural changes:**
1. Every FC6 mutation is Worker-routed (`/admin/users/*`, `/admin/admins/*`) — Identity Toolkit REST calls for Auth admin ops (suspend/ban/email-change/create/lookup), rank-guarded staff set/remove so no admin can touch or create a second founder.
2. `firebase.js` gained `fsTimestamp` — Worker-created docs now stamp a real Firestore `timestampValue`, matching client `serverTimestamp()` docs, so no field silently splits into "string on some docs, Timestamp on others."
3. `AdminRepository` gained an unmemoized `getAdminProfileForUid` read path — deliberately separate from the memoized `getAdminProfile` so viewing another uid's staff profile can never corrupt the signed-in session's own RBAC cache.
4. Founder Console `/console` ShellRoute inside the same app — admin guard, desktop-first NavigationRail/Drawer, per-section `requiredPerm` enforced in the router (`consoleSectionForLocation`).
5. Immutable `/auditLogs` collection — Worker-only writes, value-cursor pagination keeps Firestore types out of `domain/`, viewer shows before/after diffs.

## Known Issues & Technical Debt

- **One FC6 `firestore.rules` branch not yet redeployed** — the `/users` update rule gained a narrow `hasPerm('users.update')` branch after this session's rules deploy already ran. Low-risk: every FC6 mutation goes through the Worker (service account, bypasses rules), so nothing built this session actually depends on this branch being live.
- **Zero on-device E2E runs across Marketplace V2 (M8–M14) and Phase 7 (FC1–FC6)** — all sessions code-only. Device is `R5CNC0NK6ZT`.
- **Full demo re-seed still owed** (7 shops/53 products/RBAC/orders) — needs one temporary relaxed-rules pass (`allow write: if isSignedIn()` on seed collections, regenerated from current rules since FC4–6 added collections), then restore real rules + redeploy.
- **Founder has no `/admins` doc on device yet** → Console row appears only once RBAC is seeded (break-glass founder-uid already covers `/finance`).
- **On-device SDK quirk (documented lesson):** `WriteBatch.commit()` immediately after a Firebase Auth account switch returns permission-denied even with correct rules; plain `.set()` never does. Seed script works around it.
- **User detail page has no get-by-uid read** — `AdminUsersRepository` only exposes exact email/phone lookups (per the FC6 spec), so `UserDetailBloc` refreshes the post-mutation user via `getByEmail`, and the detail page requires a `ManagedUser` seed from the list row's `extra` (a bare deep link shows a "go back" empty state rather than crashing).
- **TODO/FIXME density: 0** in `lib/` — clean by that signal, but doesn't substitute for the missing device verification.
- **Uncommitted working-tree changes** at analysis time: FC6 work (this session) plus a pre-existing `lib/dev/seed_demo_data.dart` hardening pass; untracked `.flutter_aab_build.log`, `.flutter_seed_full.log`, and a stray `Docs/Brand/Product Images/Unconfirmed 463581.crdownload` (incomplete browser download — likely delete, don't commit).

## Design Decisions & Business Rules

- Money is integer piasters everywhere (wire + Firestore); Shoppy (the architecture ancestor) used `double` and that caused real bugs — never repeat.
- One app, three public roles (customer/owner/courier) chosen at signup, plus a staff console gated by RBAC — not separate apps.
- V1 ops: COD only; Marketplace V2 replaced shop-owned couriers with a shared platform driver pool (decision 2026-07-11).
- Commission: 5% (bps-based), round-half-up, snapshotted onto the order at creation time so a stale/tampered client total can never land on the doc; payable flips to true only on the `delivered` transition (rules-enforced, one-way).
- Audit logs are immutable and Worker-only: the app never writes `/auditLogs` directly; every `/admin/*` mutation goes through the Worker's perm middleware + audit writer (decision FC2/FC4, 2026-07-12/13).
- Staff rank guard: a caller may only set/remove an `/admins` doc whose CURRENT and NEW rank are both strictly below their own — this is what makes creating a second founder or an admin editing a founder structurally impossible, not just UI-hidden (decision FC6, 2026-07-13).
- Extra per-admin permissions are additive-only (`role.permissions ∪ extras`) — there is no way to grant a role's permissions and then revoke one via the console; that would require a role change instead (decision FC6, 2026-07-13).
- Console section visibility is permission-driven (`visibleConsoleSections`), and the router re-enforces per-section perms — UI hiding alone is never the security boundary.
- Seed script writes every doc individually with retry — never `WriteBatch` (on-device SDK quirk, 2026-07-13).
- Arabic lexicon is one canonical word per concept, centrally tracked in `Docs/Brand/BRAND.md` — never invent a synonym ad hoc.
- Firebase is real from day 1 in every phase — no mocked auth, ever (Shoppy lesson).
- Full E2E regression (R0) deliberately runs ONCE at the very end of the whole plan (decision 2026-07-11), rather than per-phase, to avoid repeated expensive device sessions during code-only sprints.

## How to Build / Run / Test / Deploy

```bash
# Build (Android)
flutter build apk   # or: flutter build appbundle

# Run (dev, on connected device)
flutter run -d R5CNC0NK6ZT

# Seed demo data (device; keep phone unlocked + app foregrounded the whole run)
flutter run -t lib/dev/seed_demo_data.dart -d R5CNC0NK6ZT

# Test (the three gates)
flutter analyze
flutter test
dart run scripts/check_i18n_parity.dart

# Deploy (manual, user-side)
npx -y firebase-tools deploy --only firestore:rules --project dukkan-93042   # + indexes
# - Cloudflare: deploy worker/ (see worker/README.md)
# - Play Console: internal track upload (needs keystore — Docs/RELEASE.md §1)
```

**Environment requirements:** Flutter SDK at `C:\src\flutter\bin` (prepend to PATH each shell);
Firebase project `dukkan-93042` configured via `flutterfire configure`; device `R5CNC0NK6ZT`
(Galaxy S21 Ultra) for on-device testing (Bedtime Mode 19:00–07:00; freezes backgrounded apps).
Demo accounts: owner `owner@dukkan.dev`, couriers `courier1/2@dukkan.dev`, customers
`customer1-3@dukkan.dev` (dev-only passwords in `dukkan-status` skill). Founder account:
`ahmedgaid14@gmail.com` (uid hardcoded in `AppConfig.founderUid`).

## Integrations & Services

- **Firebase**: Auth (email+password), Firestore (primary DB), Cloud Messaging (push), Crashlytics (crash reporting). Configured via `firebase_options.dart` / `.firebaserc`.
- **Cloudflare Worker** (`worker/`): verifies Firebase ID token → R2 image upload; relays FCM push (`/notify`); serves the `/admin/*` API with permission middleware + audit writer, so the app never holds R2/FCM server keys and admin mutations are centrally logged.

## Database Overview

**Engine:** Cloud Firestore. Key collections:

```
/users/{uid}                       role: customer|owner|courier, name, phone, address?,
                                    status: active|suspended|banned, deleted/deletedAt/deletedBy (FC6)
/shops/{shopId}                    ownerUid, name/nameAr, logoUrl, address, isOpen, categories[]
/shops/{shopId}/collections/{id}   nameAr, nameEn, sort
/products/{id}                     shopId, priceMinor (int), category, subcategoryId, collectionIds[], stockStatus, isPromo
/orders/{id}                       shopId, customerUid, items[], totalMinor + commission snapshot fields,
                                    status (7-value enum), statusHistory[], driverUid/driverName/driverPhone
/categories/{id}                   seed-managed global taxonomy tree
/areas/{id}                        seed-managed district list (Ismailia/Abu Atwa)
/drivers/{uid}                     isOnline, isSuspended, activeOrdersCount, areaIds[]
/config/platform                   commission bps, delivery fee, driver share (singleton doc)
/admins/{uid}                      staff profile: roleId, direct perms (FC1 RBAC)
/roles/{roleId}                    named permission sets (StaffRole)
/auditLogs/{id}                    immutable, Worker-only writes; actor, action, before/after
```

Order status flow: `pending → accepted → preparing → outForDelivery → delivered | cancelled | rejected`
(unchanged since M1). Indexes: `firestore.indexes.json` — driver/courier composites + 4 `auditLogs`
composites + 1 `orders: status+createdAt`, all **deployed**.

## Auth & API

- **Auth:** Firebase Auth, email+password (phone OTP deferred). Role chosen at signup, stored on `/users/{uid}.role`. Router (`go_router`) is auth-guarded with role-based redirects; console sections additionally guarded per-permission. Console-side Auth admin ops (suspend/ban/email-change/create/lookup) go through the Worker's Identity Toolkit REST calls, never the client SDK.
- **Authorization model:** two layers — (1) Firestore security rules per-collection, role-checked via helpers (`isSignedIn()`, `isFounder()`, owner-of-shop, driver-self-write); (2) staff RBAC (`/admins` + `/roles` → `Permissions`), enforced in-app (section visibility + router) and in the Worker's `/admin/*` perm middleware (rank-guarded for staff set/remove). Founder break-glass via `AppConfig.founderUid`.
- **API surface:** Cloudflare Worker — image upload, `/notify` push relay, `/admin/*` endpoints: `ping`, `audit`, `users/{set-disabled,set-persona-role,change-email,soft-delete,restore,create,lookup}`, `admins/{set,remove}` (all perm-checked, audit-logged).

## Quality: Testing, Performance, Security

- **Testing status:** `flutter_test`, 181/181 passing (unit + widget + bloc, incl. console shell, audit, dashboard, users, user-detail blocs + model parsing tests). i18n parity script enforces 378 matching ar/en keys. Zero on-device E2E runs for Marketplace V2 + Phase 7 — biggest testing gap.
- **Performance:** Parallel `Future.wait` loads with single BLoC emit (no double-loading flicker) — a Shoppy lesson applied throughout. Firestore aggregate queries (`count()`, `sum()`) for finance summary and console dashboard instead of document downloads; dashboard refreshes silently every 60s; user list paginated by `FieldPath.documentId` (never `createdAt`, whose Firestore type can differ between client- and Worker-created docs).
- **Security:** RBAC/audit/indexes rules are now deployed to `dukkan-93042` (this session) — one narrow FC6 `/users` rule branch added afterward is still pending redeploy (low-risk, Worker bypasses rules for its own writes; see Known Issues). Money/commission fields are rules-enforced one-way to prevent client tampering. Admin mutations only via Worker (perm middleware + immutable audit trail); staff rank guard structurally blocks privilege escalation to/past founder. Keystore password leak in `key.properties.example` was caught and reverted 2026-07-13 (never entered git history; real password lives in gitignored `android/key.properties`). No secrets found in tracked files during this scan.

---

> 📄 Maintained by the `ag-project-md` skill. Update it after meaningful changes —
> stale status is worse than no status. Manual edits welcome; the skill preserves them.
