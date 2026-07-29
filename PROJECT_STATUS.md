# Dukkan (دكان) — Project Status

![Status](https://img.shields.io/badge/status-active--development-brightgreen)
![Progress](https://img.shields.io/badge/progress-92%25-blue)
![Stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Firebase-informational)

> **Last Updated:** 2026-07-16 · **Updated By:** agent · **Branch analyzed:** feat/c2c-search
> 🤖 **AI agents:** read [Executive Summary](#executive-summary) +
> [AI Agent Quick Context](#ai-agent-quick-context) first — 2 minutes gets you 90% of the picture.

## Executive Summary

Two-sided grocery marketplace app for Egypt: customers order from neighborhood shops (دكاكين),
shop owners manage catalog/orders, drivers (مندوبين) deliver. One Flutter app, three public roles
plus a staff Founder Console, Arabic-first RTL. Clean Architecture + BLoC + Firebase
(Auth/Firestore/Storage/FCM), COD-only v1. Phases 1–6 (Foundation → Customer core → Owner core →
Polish → Release prep → Marketplace V2) are **code-complete** (M14, 2026-07-12). **Phase 7 Founder
Console** (18-session back-office plan) is deep in progress: **FC1–FC15 code-complete** (through
2026-07-15) — RBAC, Worker admin API, `/console` shell, audit log, live dashboard, and management
verticals for users, shops, products, taxonomy/geo, orders, drivers, platform settings,
notification center, media library, plus impersonation + dev tools. Gates green (analyze 0, tests
198/198, i18n parity 684). **Firestore rules + indexes and the Cloudflare Worker are now
behind** — many branches/routes added across FC6–FC15 since the last 2026-07-13 deploy, so a fresh
`firestore.rules`/`firestore.indexes.json` deploy AND a Worker deploy are both owed (user).
Zero on-device E2E across Marketplace V2 + Phase 7; full R0 regression still runs once at the end.

## AI Agent Quick Context

- **Current goal:** FC16 — promotions (coupons/banners/featured) (`Docs/plan/founder-console-plan/FILE_16_PROMOTIONS.md`).
- **Architecture:** Flutter + Firebase, Clean Architecture (domain/data/presentation) + BLoC + get_it + go_router; Cloudflare Worker for R2 upload, push relay, and the `/admin/*` API.
- **Hard constraints:** money = integer piasters only (never `double`); Arabic/RTL-first, i18n ar/en parity is build-blocking; tokens only via `AppColors`/theme, no raw hex; no new deps without asking; Firebase real from day 1 (no mocks).
- **Key conventions:** one Arabic word per concept (lexicon in `Docs/Brand/BRAND.md`); domain never imports data (console repos keep Firestore types out of domain via value cursors); every empty/error/loading state is designed, never bare; every privileged mutation goes through the Worker (`/admin/*`), never a direct client Firestore/Auth write, so it's permission-checked + audited in one place.
- **Do NOT:** touch `firestore.rules`/Worker deploys without telling the user; don't reintroduce `double` for money; don't add socket-based connectivity checks (Shoppy lesson — use the HTTP probe in `lib/core/network/network_info.dart`); don't use `WriteBatch` in the seed script (on-device SDK quirk — individual `.set()` with retry only); don't reuse the memoized `AdminRepository.getAdminProfile` for viewing another uid's staff profile — use `getAdminProfileForUid` (unmemoized) or you corrupt the signed-in session's RBAC cache.
- **Current priorities:** (1) FC16 promotions, (2) USER: deploy the Cloudflare Worker (many `/admin/*` routes now live only in code), (3) USER: redeploy `firestore.rules` + `firestore.indexes.json` (FC6–FC13 added branches/indexes after the 07-13 deploy). Phase 6 R0 full E2E runs once at the end, before release.
- **How to continue safely:** recall `dukkan-resume` skill (reads `dukkan-status` + `Docs/plan/dukkan-roadmap.md`) before picking work; for Phase 7 load `Docs/plan/founder-console-plan/FILE_00_INDEX.md` then one FILE_NN per session; run gates (`flutter analyze`, `flutter test`, `dart run scripts/check_i18n_parity.dart`) before "done".
- **Likely next files to edit:** `lib/presentation/console/promotions/` (new), `lib/{domain,data}/promotions/` (new), `worker/src/admin.js` (promo routes if needed), `firestore.rules` (promo/coupon collection), `firestore.indexes.json`.
- **Deeper truth lives in:** `Docs/plan/dukkan-roadmap.md` (phase/session authority), `dukkan-status` skill (live NEXT ACTION/blockers), `Docs/plan/founder-console-plan/FILE_00_INDEX.md` (Phase 7 session detail), `Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md` (Phase 5 detail), `Docs/Brand/BRAND.md` (brand + lexicon), `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` (hard-won lessons).

## What Is This Project?

Dukkan is a two-sided grocery marketplace for Egypt: customers browse nearby shops and order
groceries; shop owners list products and manage incoming orders; drivers (added in Marketplace
V2) deliver assigned orders; staff/founder manage the whole platform from an in-app Founder
Console (Phase 7). UI/UX inspiration is the Ben Soliman app (Arabic retail ordering: promo
carousel, category grid, product cards with inline add-to-cart, order-tracking stepper). Brand
aim: "your neighborhood shop, in your pocket" — premium, minimal, distinctly Dukkan, not a generic
marketplace clone.

**Maturity:** beta — customer/owner/courier features code-complete with 198/198 unit/widget tests
passing; Founder Console 15/18 sessions in; blocked on device-side verification, a fresh Worker +
rules/indexes deploy, and store release steps.

## Progress Overview

> ⚠️ Percentages are **estimates** inferred from roadmap position, code, and tests.

| Area | Progress | Status |
|---|---|---|
| **Overall** | `█████████░ 92%` | Phases 1–6 code-complete; Phase 7 at FC15/18; device regression + deploys + release ops remain |
| Mobile (Flutter app) | `██████████ 98%` | Customer, owner, courier flows all built; full console (15 verticals) in-app |
| Admin Panel (Founder Console) | `████████░░ 83%` | FC1–FC15 of 18: RBAC, admin API, shell, audit, dashboard, users, shops, products, taxonomy/geo, orders, drivers, settings, notifications, media, impersonation/devtools |
| Backend (Firebase) | `████████░░ 85%` | Auth/Firestore/FCM wired; rules/indexes coded through FC13 but **NOT redeployed** since 2026-07-13 |
| Storage/API (Cloudflare Worker) | `███████░░░ 70%` | Upload + push relay + `/admin/*` (users/admins/shops/orders/notify/media/impersonate/devtools) coded; **user must deploy** |
| Authentication | `██████████ 100%` | Email/password + role signup, auth-guarded router, staff RBAC layer, impersonation tokens |
| Database (Firestore) | `█████████░ 88%` | Schema stable incl. `/admins /roles /auditLogs /notificationHistory`; new rules/indexes since 07-13 deploy pending |
| Testing | `████████░░ 80%` | 198/198 unit/widget/bloc tests green; zero on-device E2E yet (R0 pending) |
| i18n (ar/en) | `██████████ 100%` | Parity script enforced, 684 keys, build-blocking |
| Release/Deployment | `████░░░░░░ 40%` | Icon/splash done; keystore, screenshots, Play upload, live Crashlytics check pending (user/device side) |
| Documentation | `█████████░ 90%` | Roadmap, brand, plan files (incl. founder-console 18-session plan), status skill all current |

## Architecture & Stack

**Stack:** Flutter (Dart SDK ^3.12.2), Firebase (`firebase_core` 4.11, `firebase_auth` 6.5,
`cloud_firestore` 6.6, `firebase_messaging` 16.0, `firebase_crashlytics` 5.0), `flutter_bloc` 9.1,
`go_router` 17.3, `get_it` 9.2, `equatable`, `intl`, `shared_preferences`, `image_picker`. No
backend server except a Cloudflare Worker (`worker/`) for R2 image upload, FCM push relay, and the
permission-checked `/admin/*` API.

- Clean Architecture: `domain/` (entities, repository interfaces, usecases) never imports `data/`.
- State management: BLoC per feature vertical (auth, cart, orders, favorites, catalog, driver, finance, audit, dashboard, and each console vertical).
- Money: integer piasters everywhere on the wire and in Firestore; formatted only at the UI edge (`lib/core/money.dart`).
- Connectivity: HTTP probe (`NetworkInfo`), not socket-based checkers (Shoppy lesson).
- Realtime: Firestore snapshots for orders/collections/deliveries; local cache datasources for offline read; console repos deliberately no-cache.
- i18n: ARB files (`lib/l10n/`) with a parity-check script, RTL-first `MaterialApp`.
- Image storage: Cloudflare Worker verifies Firebase ID token → R2 put (app never holds R2 keys).
- Founder Console: `/console` ShellRoute (desktop-first NavigationRail/Drawer), per-section permission guard, dashboard uses Firestore aggregate `count()`/`sum()` (no doc downloads).
- Every privileged console mutation is Worker-routed (`/admin/*`) — never a direct client Firestore/Auth write — so it's permission-checked server-side and written to the immutable audit trail in one place. Auth admin ops (suspend/ban/email-change/create/lookup) go through Identity Toolkit REST calls (`worker/src/firebase.js`'s `identityToolkitCall`), authenticated as the service account. Impersonation mints target + return custom tokens (rank-guarded).

### Folder Structure

```
lib/
  core/           theme tokens (AppColors/Spacing/Radius/Typography), money, network, router,
                  search, config, di, impersonation, notifications
  domain/         entities + repository interfaces + usecases, per vertical (auth, shop, product,
                  order, cart, favorites, storage, taxonomy, areas, driver, config, finance,
                  collections, admin, audit, dashboard, media, devtools, and admin-* verticals)
  data/           Firestore/local datasources + repository impls, mirrors domain verticals
  presentation/   pages + BLoCs per feature (auth, home, shop, catalog, cart, orders, favorites,
                  search, settings, driver, finance, console/) + shared widgets/common
  l10n/           app_ar.arb / app_en.arb source + generated
  dev/            seed.dart (reusable runSeed) + seed_demo_data.dart entrypoint + migrations/
worker/           Cloudflare Worker — R2 upload, FCM push relay ("/notify"), /admin/* API
                  (src/{index,firebase,admin}.js — perm middleware + audit writer)
scripts/          check_i18n_parity.dart
test/             unit + widget + bloc tests (198 tests across 36 files)
Docs/
  plan/           dukkan-roadmap.md (authority) + marketplace-v2-plan/ (M1-M14)
                  + founder-console-plan/ (FC FILE_00-FILE_18)
  Brand/          BRAND.md (tokens, voice, Arabic lexicon)
  legacy/         SHOPPY_PROJECT_KNOWLEDGE.md (architecture ancestor + fixed bugs)
  testing/        E2E_MASTER_PROMPT.md + e2e-reports/
```

### Main Modules

- `lib/domain/*` / `lib/data/*` — one vertical per concept: auth, shop, product, order, cart,
  favorites, storage, taxonomy, areas, driver, config, finance, collections, admin (RBAC), audit,
  dashboard, media, devtools, plus the console admin repos (users, shops, products, taxonomy, geo,
  orders, drivers, settings, notifications).
- `lib/presentation/*` — one folder per feature with `bloc/`, `pages/`, `widgets/`; `console/`
  holds the Founder Console shell + all 15 verticals + shared `widgets/stat_tile.dart`.
- `worker/` — standalone Cloudflare Worker, deployed separately from the Flutter app.

### Central Files (handle with care)

| File | Why it matters | Safe to edit casually? |
|---|---|---|
| `firestore.rules` | Security rules — branches added across FC6–FC13 (users/shops/products/taxonomy/geo/orders-notes/drivers/config/notify) are **NOT redeployed** since the 2026-07-13 deploy; Worker bypasses rules for its own writes, but customer/owner/console client reads/writes depend on the live rules | ⚠️ No |
| `firestore.indexes.json` | Composite indexes — FC10 (orders status+createdAt), FC11 (driver+status+createdAt), FC13 (notify) added after last deploy; **redeploy owed** | ⚠️ No |
| `lib/core/money.dart` | Integer-piaster money math, round-half-up commission calc | ⚠️ No |
| `worker/src/{index,firebase,admin}.js` | All `/admin/*` routes + perm middleware + audit writer; **not deployed** — code-only until user runs wrangler | ⚠️ No |
| `Docs/plan/dukkan-roadmap.md` | Single "what next" authority — read before picking any task | ⚠️ No (roadmap edits are session-gated) |
| `Docs/Brand/BRAND.md` | Arabic lexicon — one word per concept, must stay in sync with strings | ⚠️ No |
| `pubspec.yaml` | No new deps without asking | ⚠️ No |

## Features

### ✅ Completed
- [x] Foundation — scaffold, theme, i18n, Firebase auth + roles (F1–F3)
- [x] Customer core — browse (home/shop/search), cart/checkout, orders with realtime status (C1–C4)
- [x] Shop owner core — onboarding, catalog CRUD, order desk (S1–S3)
- [x] Polish — favorites, promos, settings/dark-mode, FCM notifications, ratings (P1–P3)
- [x] Release prep — launcher icon + splash (official pack), Crashlytics wired, signing config wired (R1b + part of R1/R2)
- [x] Marketplace V2 — order details/timeline, global taxonomy, shop collections, driver pool (areas/assignment/courier shell/push), commission ledger + founder finance page, `orderDelivered` push (M1–M14 code-complete)
- [x] Founder Console FC1–FC5 — RBAC foundation (`/admins`+`/roles`), Worker `/admin/*` API (perm middleware + audit writer), `/console` shell (admin guard, desktop-first nav), audit log vertical (immutable `/auditLogs`, filtered/paginated viewer + diff sheet), live dashboard (aggregate stat tiles, 7-day chart, recent activity)
- [x] Founder Console FC6 — user management: Worker `/admin/users/*` + rank-guarded `/admin/admins/*`, `/console/users` list + `/console/users/:uid` detail
- [x] Founder Console FC7 — shop management: lifecycle (pending/active/suspended), featured/verified flags, soft delete, Worker-only ownership transfer, console board + detail + create
- [x] Founder Console FC8 — product admin: soft delete, console board, filters, bulk ops (price/stock/promo/featured/category via chunked WriteBatch), founder-only hard delete
- [x] Founder Console FC9 — taxonomy + geo: console-editable categories (visibility/icon/reorder) + areas (governorate/city/active/fee-override); PlaceOrder resolves area fee override
- [x] Founder Console FC10 — order admin: Worker force-status / reassign-driver / cancel + append-only notes, staff order board + detail, forced-transition audit chip
- [x] Founder Console FC11 — driver admin: activation, areas/capacity, vehicle fields, ID-doc upload, verified toggle, performance card
- [x] Founder Console FC12 — platform settings: config editor (rates/delivery/contact), feature flags, maintenance mode + minSupportedBuild version gates (boot-time router redirects)
- [x] Founder Console FC13 — notification center: role-topic FCM subscribe, Worker broadcast + direct push with immutable history + audit, compose/history/templates pages, dashboard failed-pushes tile
- [x] Founder Console FC14 — media library: Worker R2 browse/stats/delete, orphan + broken-reference finders, folder upload, multi-select hard delete
- [x] Founder Console FC15 — impersonation + dev tools: Worker `/admin/impersonate` (rank-guarded token mint) + banner surviving app-kill via ID-token claim; `/admin/devtools/*` (fake customers/orders/cleanup), reusable `lib/dev/seed.dart` + `migrations/` registry driving a console devtools page

### 🟡 Partially Complete
- [ ] Phase 7 Founder Console — 15/18 sessions done; next: FC16 promotions, then FC17 search/reports/export, FC18 acceptance
- [ ] R1 — Store prep: icon/splash/listing copy done; screenshots + feature graphic blocked on seeded device run
- [ ] R2 — Ship: Crashlytics + signing wired; user still needs keystore, on-device Crashlytics check, Play internal-track upload
- [ ] R0 — full on-device acceptance + E2E regression not yet run (deferred to end of plan, before release)
- [ ] Demo data seed — script refactored into reusable `lib/dev/seed.dart`; full re-seed still needs a temporary rules-relax pass (see Known Issues)

### ⬜ Not Started
- [ ] Founder Console FC16–FC18 (promotions; global search + CSV exports + reports; acceptance + security matrix + regression)
- [ ] Phone OTP auth (deferred — costs money, v1 uses email+password)
- [ ] Maps-based address entry (deferred — v1 uses manual address entry)

## Roadmap & Next Steps

Full authority: [`Docs/plan/dukkan-roadmap.md`](Docs/plan/dukkan-roadmap.md). Phase 7 session
detail: `Docs/plan/founder-console-plan/FILE_00_INDEX.md`. Marketplace V2 detail:
`Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md`.

**High Priority**
1. FC16 — promotions: coupons/banners/featured (`Docs/plan/founder-console-plan/FILE_16_PROMOTIONS.md`)
2. USER: deploy the Cloudflare Worker (`worker/README.md`) — every FC6–FC15 `/admin/*` route is code-only until this runs
3. USER: redeploy `firestore.rules` + `firestore.indexes.json` (FC6–FC13 branches/indexes added after the 2026-07-13 deploy)

**Medium Priority**
1. Re-seed full demo data on device (needs one temporary relaxed-rules pass, then restore real rules — see `dukkan-status` skill)
2. R1 screenshots + feature graphic (needs seeded device run)
3. R2 remainder — keystore generation, on-device Crashlytics live-event check, Play internal-track upload

**Low Priority**
1. FC17–FC18 (search/reports/export; acceptance/security/regression) — after FC16
2. Phase 6 R0 full E2E regression — runs once at the very end, before release
3. iOS build (assets already staged in `Dukkan Logo Assets/iOS/`)

**Current blockers:**
1. USER must deploy the Cloudflare Worker — blocks live push/upload and every `/admin/*` endpoint (users/admins/shops/orders/notify/media/impersonate/devtools) from reaching production. Code is ready; nothing is live until this deploy runs.
2. USER must redeploy `firestore.rules` + `firestore.indexes.json` — the live rules/indexes are from the 2026-07-13 deploy (FC1–FC5 era); FC6–FC13 added client-facing branches (shops/products/taxonomy/geo/orders-notes/drivers/config) and indexes that aren't live yet.

## Recent Work

- 2026-07-15 — feat(founder-console): FC15 impersonation + developer tools (`999ef9b`)
- 2026-07-15 — feat(founder-console): FC14 media library — R2 browse, orphan/broken finders, storage stats (`95d731d`)
- 2026-07-15 — feat(founder-console): FC13 notification center — broadcast, direct push, history, templates (`dc891e8`)
- 2026-07-15 — feat(founder-console): FC12 platform settings — config editor, feature flags, maintenance + version gates (`527f8ff`)
- 2026-07-15 — feat(founder-console): FC11 driver admin — activation, areas, capacity, vehicle, performance (`e77e744`)
- 2026-07-14 — feat(founder-console): FC10 order admin — force-status, reassign, cancel, notes (`57f8d36`)
- 2026-07-14 — feat(founder-console): FC9 taxonomy + geo — console-editable categories/areas, area fee override (`24a890b`)
- 2026-07-14 — feat(founder-console): FC8 product admin — soft delete, bulk ops, console board (`15b8459`)
- 2026-07-14 — feat(founder-console): FC7 shop management — lifecycle, flags, transfer, edit-any (`e84aad9`)
- 2026-07-13 — feat(founder-console): FC6 user management — Worker admin ops, rank-guarded staff, console UI (`4b615be`)
- earlier: FC1–FC5 (2026-07-12 → 07-13), Marketplace V2 M1–M14 + `orderDelivered` push, release prep R1b/R2, Phases 1–4.

**Recent architectural changes:**
1. Impersonation derives its "acting as" state from the ID token's `impersonatedBy` claim (not in-memory), so it survives an app kill mid-session; tokens are rank-guarded like `/admin/admins/set` (FC15).
2. `lib/dev/seed_demo_data.dart` refactored into a reusable `lib/dev/seed.dart` (`runSeed`, flag-gated phases) + a `lib/dev/migrations/` registry — both now driving a console devtools page instead of only a standalone entrypoint (FC15).
3. Notification center: role-topic FCM subscribe/unsubscribe on login/logout; Worker broadcast/direct writes an immutable `/notificationHistory` doc + audit entry (FC13).
4. Platform version/maintenance gating happens in `AppRouter._redirect` at boot (fail-open on fetch error, staff bypass maintenance) → dedicated `/maintenance` + `/update-required` pages (FC12).
5. Every FC6–FC15 privileged mutation is Worker-routed with perm middleware + audit; staff rank guard structurally blocks touching/creating a founder or an equal/higher-ranked admin.

## Known Issues & Technical Debt

- **Firestore rules + indexes are behind the code** — the live deploy is from 2026-07-13 (FC1–FC5). FC6–FC13 added client-facing rule branches (shops/products/taxonomy/geo/orders-notes/drivers/config/notify) and new composite indexes (`firestore.indexes.json`) that are **not deployed**. Console/customer/owner flows that rely on those reads/writes will be denied on the live project until a redeploy. Worker-routed writes are unaffected (service account bypasses rules).
- **Cloudflare Worker not deployed** — all FC6–FC15 `/admin/*` routes exist only in `worker/src/`. No admin action, push, or upload reaches production until the user deploys.
- **Zero on-device E2E runs across Marketplace V2 (M8–M14) and Phase 7 (FC1–FC15)** — all sessions code-only. Device is `R5CNC0NK6ZT`.
- **Full demo re-seed still owed** (7 shops/53 products/RBAC/orders + drivers/config/taxonomy/areas) — needs one temporary relaxed-rules pass (`allow write: if isSignedIn()` on seed collections), then restore real rules + redeploy. Seed logic now lives in `lib/dev/seed.dart` (`runSeed`).
- **Founder has no `/admins` doc on device yet** → Console appears only once RBAC is seeded (break-glass founder-uid already covers `/finance` and the devtools page).
- **On-device SDK quirk (documented lesson):** `WriteBatch.commit()` immediately after a Firebase Auth account switch returns permission-denied even with correct rules; plain `.set()` never does. Seed uses individual writes + retry.
- **User detail page has no get-by-uid read** — `AdminUsersRepository` exposes only exact email/phone lookups (per the FC6 spec), so `UserDetailBloc` refreshes post-mutation via `getByEmail`, and the detail page needs a `ManagedUser` seed from the list row's `extra` (a bare deep link shows a "go back" empty state, not a crash).
- **TODO/FIXME density: 0** in `lib/` — clean by that signal, but no substitute for the missing device verification.
- **Uncommitted / untracked at analysis time:** `Docs/plan/dukkan-roadmap.md` modified (working tree); untracked `.flutter_aab_build.log`, `.flutter_seed_full.log`, a `.modeer/` dir, and a stray `Docs/Brand/Product Images/Unconfirmed 463581.crdownload` (incomplete browser download — likely delete, don't commit).

## Design Decisions & Business Rules

- Money is integer piasters everywhere (wire + Firestore); Shoppy (the architecture ancestor) used `double` and that caused real bugs — never repeat.
- One app, three public roles (customer/owner/courier) chosen at signup, plus a staff console gated by RBAC — not separate apps.
- V1 ops: COD only; Marketplace V2 replaced shop-owned couriers with a shared platform driver pool (decision 2026-07-11).
- Commission: 5% (bps-based), round-half-up, snapshotted onto the order at creation time so a stale/tampered client total can never land on the doc; payable flips to true only on the `delivered` transition (rules-enforced, one-way).
- Audit logs are immutable and Worker-only: the app never writes `/auditLogs` directly; every `/admin/*` mutation goes through the Worker's perm middleware + audit writer.
- Staff rank guard: a caller may only set/remove an `/admins` doc whose CURRENT and NEW rank are both strictly below their own — this makes creating a second founder or an admin editing a founder structurally impossible, not just UI-hidden (FC6). Impersonation reuses the same rank guard (FC15).
- Extra per-admin permissions are additive-only (`role.permissions ∪ extras`) — revoking a single role permission requires a role change instead (FC6).
- Console section visibility is permission-driven (`visibleConsoleSections`), and the router re-enforces per-section perms — UI hiding is never the security boundary.
- Impersonation state is derived from the ID token's `impersonatedBy` claim, not in-memory, so it survives an app kill (FC15).
- Seed script writes every doc individually with retry — never `WriteBatch` (on-device SDK quirk).
- Arabic lexicon is one canonical word per concept, centrally tracked in `Docs/Brand/BRAND.md` — never invent a synonym ad hoc.
- Firebase is real from day 1 in every phase — no mocked auth, ever (Shoppy lesson).
- Full E2E regression (R0) deliberately runs ONCE at the very end of the whole plan (2026-07-11), not per-phase, to avoid repeated expensive device sessions during code-only sprints.

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
npx -y firebase-tools deploy --only firestore:rules,firestore:indexes --project dukkan-93042
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

- **Firebase**: Auth (email+password), Firestore (primary DB), Cloud Messaging (push + role topics), Crashlytics (crash reporting). Configured via `firebase_options.dart` / `.firebaserc`.
- **Cloudflare Worker** (`worker/`): verifies Firebase ID token → R2 image upload; relays FCM push (`/notify`, `/admin/notify/*`); serves the `/admin/*` API with permission middleware + audit writer, so the app never holds R2/FCM server keys and admin mutations are centrally logged. **Deploy owed.**

## Database Overview

**Engine:** Cloud Firestore. Key collections:

```
/users/{uid}                       role: customer|owner|courier, name, phone, address?,
                                    status: active|suspended|banned, deleted/deletedAt/deletedBy
/shops/{shopId}                    ownerUid, name/nameAr, logoUrl, address, isOpen, categories[],
                                    status: pending|active|suspended, featured, verified, deleted*
/shops/{shopId}/collections/{id}   nameAr, nameEn, sort
/products/{id}                     shopId, priceMinor (int), category, subcategoryId,
                                    collectionIds[], stockStatus, isPromo, isFeatured, deleted*
/orders/{id}                       shopId, customerUid, items[], totalMinor + commission snapshot,
                                    status (7-value enum), statusHistory[], driverUid/Name/Phone
/orders/{id}/notes/{noteId}        append-only staff notes (FC10)
/categories/{id}                   seed/console-managed taxonomy tree (isVisible, iconName)
/areas/{id}                        console-managed districts (governorate/city/active/fee override)
/drivers/{uid}                     isOnline, isSuspended, activeOrdersCount, areaIds[], capacity,
                                    vehicleType/Plate, idDocUrl, isVerified
/config/platform                   commission bps, delivery fee, driver share, minOrder, vat,
                                    support contacts, maintenanceMode, minSupportedBuild
/config/flags                      feature flags (FC12)
/admins/{uid}                      staff profile: roleId, rank, direct perms (FC1 RBAC)
/roles/{roleId}                    named permission sets (StaffRole)
/auditLogs/{id}                    immutable, Worker-only writes; actor, action, before/after
/notificationHistory/{id}          immutable broadcast/direct push log (FC13)
```

Order status flow: `pending → accepted → preparing → outForDelivery → delivered | cancelled | rejected`
(unchanged since M1). Indexes: `firestore.indexes.json` — driver/courier composites + 4 `auditLogs`
composites + orders `status+createdAt` + driver `status+createdAt` + notify; **the post-07-13 additions
are not yet deployed.**

## Auth & API

- **Auth:** Firebase Auth, email+password (phone OTP deferred). Role chosen at signup, stored on `/users/{uid}.role`. Router (`go_router`) is auth-guarded with role-based redirects; console sections additionally guarded per-permission; boot-time maintenance/min-build gates redirect to `/maintenance` or `/update-required`. Console-side Auth admin ops go through the Worker's Identity Toolkit REST calls, never the client SDK. Impersonation logs the founder in as a target user via a Worker-minted custom token.
- **Authorization model:** two layers — (1) Firestore security rules per-collection, role-checked via helpers (`isSignedIn()`, `isFounder()`, `hasPerm()`, owner-of-shop, driver-self-write); (2) staff RBAC (`/admins` + `/roles` → `Permissions`), enforced in-app (section visibility + router) and in the Worker's `/admin/*` perm middleware (rank-guarded for staff/impersonation). Founder break-glass via `AppConfig.founderUid`.
- **API surface:** Cloudflare Worker — image upload, `/notify` push relay, and `/admin/*`: `ping`, `audit`, `users/*`, `admins/*`, `shops/transfer`, `orders/{force-status,reassign-driver,cancel}`, `notify/{broadcast,user}`, `media/{list,stats,delete}`, `impersonate`, `devtools/{fake-customers,fake-orders,fake-cleanup}` (all perm-checked, audit-logged).

## Quality: Testing, Performance, Security

- **Testing status:** `flutter_test`, 198/198 passing (unit + widget + bloc across 36 files, incl. console shell, audit, dashboard, users, user-detail, media-diff, and model-parsing tests). i18n parity script enforces 684 matching ar/en keys. Zero on-device E2E runs for Marketplace V2 + Phase 7 — biggest testing gap.
- **Performance:** Parallel `Future.wait` loads with single BLoC emit (no double-loading flicker) — a Shoppy lesson applied throughout. Firestore aggregate queries (`count()`, `sum()`) for finance + dashboard instead of document downloads; dashboard refreshes silently every 60s; list pagination by `FieldPath.documentId` / value cursors (never `createdAt`, whose Firestore type can differ between client- and Worker-created docs).
- **Security:** Money/commission fields are rules-enforced one-way to prevent client tampering. Admin mutations only via Worker (perm middleware + immutable audit trail); staff rank guard structurally blocks privilege escalation to/past founder; impersonation is rank-guarded and token-claim-derived. **Caveat: the live Firestore rules are from the 2026-07-13 deploy — FC6–FC13 rule branches are coded but not yet live (redeploy owed), and the Worker itself is not deployed.** Keystore password lives only in gitignored `android/key.properties`. No secrets found in tracked files during this scan.

---

> 📄 Maintained by the `ag-project-md` skill. Update it after meaningful changes —
> stale status is worse than no status. Manual edits welcome; the skill preserves them.
