# Dukkan (دكان) — Project Status

![Status](https://img.shields.io/badge/status-active--development-brightgreen)
![Progress](https://img.shields.io/badge/progress-90%25-blue)
![Stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Firebase-informational)

> **Last Updated:** 2026-07-12 · **Updated By:** agent · **Branch analyzed:** feat/c2c-search
> 🤖 **AI agents:** read [Executive Summary](#executive-summary) +
> [AI Agent Quick Context](#ai-agent-quick-context) first — 2 minutes gets you 90% of the picture.

## Executive Summary

Two-sided grocery marketplace app for Egypt: customers order from neighborhood shops (دكاكين),
shop owners manage catalog/orders, drivers (مندوبين) deliver. One Flutter app, three roles,
Arabic-first RTL. Clean Architecture + BLoC + Firebase (Auth/Firestore/Storage/FCM), COD-only v1.
All 6 planned phases (Foundation → Customer core → Owner core → Polish → Release prep →
Marketplace V2: taxonomy/collections/drivers/commission) are **code-complete** as of M14
(2026-07-12). What's left is entirely device-side: on-device E2E regression (R0), Firestore
rules/Worker deploys, Play Store release steps. No further Flutter code is planned until R0
surfaces bugs.

## AI Agent Quick Context

- **Current goal:** Phase 6 R0 — full on-device E2E regression (`Docs/testing/E2E_MASTER_PROMPT.md`), then release.
- **Architecture:** Flutter + Firebase, Clean Architecture (domain/data/presentation) + BLoC + get_it + go_router.
- **Hard constraints:** money = integer piasters only (never `double`); Arabic/RTL-first, i18n ar/en parity is build-blocking; tokens only via `AppColors`/theme, no raw hex; no new deps without asking; Firebase real from day 1 (no mocks).
- **Key conventions:** one Arabic word per concept (lexicon in `Docs/Brand/BRAND.md`); domain never imports data; every empty/error/loading state is designed, never bare.
- **Do NOT:** touch `firestore.rules` deploy without telling the user (console-deployed manually, several blocks currently undeployed — see Known Issues); don't reintroduce `double` for money; don't add socket-based connectivity checks (Shoppy lesson — use HTTP probe, `lib/core/network/network_info.dart`).
- **Current priorities:** (1) Phase 6 R0 on-device regression, (2) deploy pending `firestore.rules` blocks + Cloudflare Worker, (3) Play Store release (keystore, screenshots, Crashlytics live check).
- **How to continue safely:** recall `dukkan-resume` skill (reads `dukkan-status` + `Docs/plan/dukkan-roadmap.md`) before picking work; run gates (`flutter analyze`, `flutter test`, `dart run scripts/check_i18n_parity.dart`) before "done".
- **Likely next files to edit:** none expected — next work is device testing; if bugs surface, likely areas are `lib/presentation/orders/`, `lib/data/*/datasources/`, `firestore.rules`.
- **Deeper truth lives in:** `Docs/plan/dukkan-roadmap.md` (phase/session authority), `dukkan-status` skill (live NEXT ACTION/blockers), `Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md` (Phase 5 session detail), `Docs/Brand/BRAND.md` (brand + lexicon), `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` (hard-won lessons).

## What Is This Project?

Dukkan is a two-sided grocery marketplace for Egypt: customers browse nearby shops and order
groceries; shop owners list products and manage incoming orders; drivers (added in Marketplace
V2) deliver assigned orders. UI/UX inspiration is the Ben Soliman app (Arabic retail ordering:
promo carousel, category grid, product cards with inline add-to-cart, order-tracking stepper).
Brand aim: "your neighborhood shop, in your pocket" — premium, minimal, distinctly Dukkan, not a
generic marketplace clone.

**Maturity:** beta — all planned features code-complete with 118/118 unit/widget tests passing;
blocked only on device-side verification and store release steps, not further feature work.

## Progress Overview

> ⚠️ Percentages are **estimates** inferred from roadmap position, code, and tests.

| Area | Progress | Status |
|---|---|---|
| **Overall** | `█████████░ 90%` | Code-complete through Phase 5 (M14); only device regression + release ops remain |
| Mobile (Flutter app) | `█████████░ 95%` | Customer, owner, courier flows all built |
| Backend (Firebase) | `████████░░ 85%` | Auth/Firestore/FCM wired; several rules blocks undeployed |
| Storage (Cloudflare Worker/R2) | `███████░░░ 70%` | Code done; user must deploy Worker |
| Authentication | `██████████ 100%` | Email/password + role-based signup, auth-guarded router |
| Database (Firestore) | `████████░░ 85%` | Schema stable; rules for categories/areas/drivers/config/collections pending console deploy |
| Testing | `████████░░ 80%` | 118 unit/widget tests green; zero on-device E2E run yet (R0 pending) |
| i18n (ar/en) | `██████████ 100%` | Parity script enforced, 261 keys, build-blocking |
| Release/Deployment | `████░░░░░░ 40%` | Icon/splash done; keystore, screenshots, Play upload, live Crashlytics check pending (user/device side) |
| Documentation | `█████████░ 90%` | Roadmap, brand, plan files, status skill all current |

## Architecture & Stack

**Stack:** Flutter (Dart SDK ^3.12.2), Firebase (`firebase_core` 4.11, `firebase_auth` 6.5,
`cloud_firestore` 6.6, `firebase_messaging` 16.0, `firebase_crashlytics` 5.0), `flutter_bloc` 9.1,
`go_router` 17.3, `get_it` 9.2, `equatable`, `intl`, `shared_preferences`, `image_picker`. No
backend server except a Cloudflare Worker (`worker/`) for R2 image upload + FCM push relay.

- Clean Architecture: `domain/` (entities, repositories interfaces, usecases) never imports `data/`.
- State management: BLoC per feature vertical (auth, cart, orders, favorites, catalog, driver, finance…).
- Money: integer piasters everywhere on the wire and in Firestore; formatted only at UI edge (`lib/core/money.dart`).
- Connectivity: HTTP probe (`NetworkInfo`), not socket-based checkers (Shoppy lesson).
- Realtime: Firestore snapshots for orders/collections/deliveries; local cache datasources for offline read.
- i18n: ARB files (`lib/l10n/`) with a parity-check script, RTL-first `MaterialApp`.
- Image storage: Cloudflare Worker verifies Firebase ID token → R2 put (app never holds R2 keys).

### Folder Structure

```
lib/
  core/           theme tokens (AppColors/Spacing/Radius/Typography), money, network, router, search
  domain/         entities + repository interfaces + usecases, per vertical (auth, shop, product,
                  order, cart, favorites, storage, taxonomy, areas, driver, config, finance, collections)
  data/           Firestore/local datasources + repository impls, mirrors domain verticals
  presentation/   pages + BLoCs per feature (auth, home, shop, catalog, cart, orders, favorites,
                  search, settings, driver, finance) + shared widgets/common
  l10n/           ar.json / en.json ARB source + generated
worker/           Cloudflare Worker — R2 image upload + FCM push relay ("/notify")
scripts/          check_i18n_parity.dart
test/             unit + widget tests (22 test files)
Docs/
  plan/           dukkan-roadmap.md (authority) + marketplace-v2-plan/ (M1-M14 session files)
  Brand/          BRAND.md (tokens, voice, Arabic lexicon)
  legacy/         SHOPPY_PROJECT_KNOWLEDGE.md (architecture ancestor + fixed bugs)
  testing/        E2E_MASTER_PROMPT.md + e2e-reports/
```

### Main Modules

- `lib/domain/*` / `lib/data/*` — one vertical per vertical: auth, shop, product, order, cart,
  favorites, storage, taxonomy, areas, driver, config, finance, collections.
- `lib/presentation/*` — one folder per feature with `bloc/`, `pages/`, `widgets/`.
- `worker/` — standalone Cloudflare Worker, deployed separately from the Flutter app.

### Central Files (handle with care)

| File | Why it matters | Safe to edit casually? |
|---|---|---|
| `firestore.rules` | Security rules; several blocks are coded but NOT yet deployed (console-deployed manually) | ⚠️ No |
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
- [x] M14 code-only acceptance pass — gates green, lexicon/enum audit, E2E prompt updated with new journeys
- [x] `orderDelivered` push — owner notified when the courier marks an order delivered (M11's previously-skipped scope, added 2026-07-12)

### 🟡 Partially Complete
- [ ] R1 — Store prep: icon/splash/listing copy done; screenshots + feature graphic blocked on seeded device run
- [ ] R2 — Ship: Crashlytics + signing wired; user still needs keystore, on-device Crashlytics check, Play internal-track upload
- [ ] M14/R0 — full on-device acceptance + E2E regression not yet run

### ⬜ Not Started
- [ ] Phone OTP auth (deferred — costs money, v1 uses email+password)
- [ ] Maps-based address entry (deferred — v1 uses manual address entry)

## Roadmap & Next Steps

Full authority: [`Docs/plan/dukkan-roadmap.md`](Docs/plan/dukkan-roadmap.md). Marketplace V2
session detail: `Docs/plan/marketplace-v2-plan/FILE_00_INDEX.md`.

**High Priority**
1. Phase 6 R0 — full on-device E2E regression (`Docs/testing/E2E_MASTER_PROMPT.md`) on device `R5CNC0NK6ZT`
2. Deploy pending `firestore.rules` blocks (M1/M3/M6/M8–M13) via Firebase console
3. Deploy Cloudflare Worker (image upload + `/notify` push relay)

**Medium Priority**
1. R1 screenshots + feature graphic (needs seeded device run)
2. R2 remainder — keystore generation, on-device Crashlytics live-event check, Play internal-track upload

**Low Priority**
1. `orderDelivered` owner-notification (skipped scope from M11)
2. iOS build (assets already staged in `Dukkan Logo Assets/iOS/`)

**Current blockers:**
1. USER must deploy the Cloudflare Worker (`worker/README.md`) — blocks live push/upload only.
2. USER must deploy current `firestore.rules` via Firebase console — blocks device smoke tests only.

## Recent Work

- 2026-07-12 — chore: add brand product/shop images, run_dukkan.vbs; ignore local run logs (`6968d12`)
- 2026-07-12 — docs(dukkan): M14 acceptance — code-only verification pass (`21c5115`)
- 2026-07-12 — feat(marketplace-v2): M13 finance summary — founder-gated aggregates (`f807c40`)
- 2026-07-12 — feat(marketplace-v2): M12 commission ledger (`ed4b788`)
- 2026-07-11 — feat(driver): M11 — assignment push notification (`773c58d`)
- 2026-07-11 — feat(marketplace): M10 courier shell — deliveries list + role-aware order detail (`753dd9a`)
- 2026-07-11 — feat(orders): M9 — driver assignment transaction + owner sheet (`5b0ca5f`)
- 2026-07-11 — feat(marketplace-v2): M8 — areas + driver foundation, courier role (`4f7885d`)
- 2026-07-11 — feat(marketplace-v2): M6-M7 — shop collections CRUD + product assignment + filter (`c434eb7`)
- 2026-07-11 — feat(marketplace-v2): M3-M5 — global taxonomy + dependent dropdowns + category carry-over (`09f5273`)

**Recent architectural changes:**
1. `OrderDetailPage`/`OrderDetailBloc` widened from bool `isOwner` to `OrderViewerRole` enum (customer/owner/courier) — one page, three roles.
2. Order gained 7 commission-snapshot fields, all optional-with-default so old docs still parse.
3. Shared driver pool model replaces the earlier shop-owned-courier plan (superseded 2026-07-11).
4. `/config/platform` introduces a memoized one-shot config repo pattern (mirrors `AreasRepository`).
5. Founder-gated `/finance` route + aggregate-query Firestore rule branch (rules can't read per-document data for aggregation queries).

## Known Issues & Technical Debt

- **Several `firestore.rules` blocks are coded but undeployed**: M1 (statusHistory), M3 (`/categories`), M6 (`/collections`), M8 (`/areas`+`/drivers`), M9 (driver assignment fields), M10 (driver read/transition), M12 (`/config`), M13 (`/orders` founder aggregate branch). Must be deployed via Firebase console before any real device write-test, or writes will be rejected by the currently-live pre-M1 rules.
- **Zero on-device E2E runs across all of Marketplace V2** (M8–M14) — every session this phase was code-only, no device connected. Device is `R5CNC0NK6ZT`.
- **TODO/FIXME density: 0** in `lib/` — clean by that signal, but doesn't substitute for the missing device verification.
- **Uncommitted working-tree changes** at analysis time: `android/key.properties.example` modified, plus untracked `.flutter_aab_build.log` and a stray `Docs/Brand/Product Images/Unconfirmed 463581.crdownload` (looks like an incomplete browser download — likely should be deleted, not committed).
- **`orderDelivered` owner notification** intentionally skipped in M11 — not a bug, just unbuilt scope.

## Design Decisions & Business Rules

- Money is integer piasters everywhere (wire + Firestore); Shoppy (the architecture ancestor) used `double` and that caused real bugs — never repeat.
- One app, three roles (customer/owner/courier), chosen at signup — not separate apps.
- V1 ops: COD only, each shop delivers itself in early phases; Marketplace V2 replaced shop-owned couriers with a shared platform driver pool (decision 2026-07-11, `courier-role-plan/` superseded by session M8).
- Commission: 5% (bps-based), round-half-up, snapshotted onto the order at creation time so a stale/tampered client total can never land on the doc; payable flips to true only on the `delivered` transition (rules-enforced, one-way).
- Arabic lexicon is one canonical word per concept, centrally tracked in `Docs/Brand/BRAND.md` — never invent a synonym ad hoc.
- Firebase is real from day 1 in every phase — no mocked auth, ever (Shoppy lesson).
- Full E2E regression (R0) deliberately moved to run ONCE at the very end of the whole plan (decision 2026-07-11), rather than per-phase, to avoid repeated expensive device sessions during code-only sprints.

## How to Build / Run / Test / Deploy

```bash
# Build (Android)
flutter build apk   # or: flutter build appbundle

# Run (dev, on connected device)
flutter run -d R5CNC0NK6ZT

# Seed demo data (device)
flutter run -t lib/dev/seed_demo_data.dart -d R5CNC0NK6ZT

# Test
flutter analyze
flutter test
dart run scripts/check_i18n_parity.dart

# Deploy (manual, user-side)
# - Firebase console: deploy firestore.rules + firestore.indexes.json
# - Cloudflare: deploy worker/ (see worker/README.md)
# - Play Console: internal track upload (needs keystore — Docs/RELEASE.md §1)
```

**Environment requirements:** Flutter SDK at `C:\src\flutter\bin` (prepend to PATH each shell);
Firebase project configured via `flutterfire configure`; device `R5CNC0NK6ZT` for on-device
testing (Bedtime Mode active 19:00–07:00). Demo owner account: `owner@dukkan.dev` / `owner123`.
Founder account: `ahmedgaid14@gmail.com` (uid hardcoded in `AppConfig.founderUid`).

## Integrations & Services

- **Firebase**: Auth (email+password), Firestore (primary DB), Cloud Messaging (push), Crashlytics (crash reporting). Configured via `firebase_options.dart` / `.firebaserc`.
- **Cloudflare Worker** (`worker/`): verifies Firebase ID token → R2 image upload; also relays FCM push (`/notify` endpoint) so the app never holds R2 or FCM server keys directly.

## Database Overview

**Engine:** Cloud Firestore. Key collections:

```
/users/{uid}                       role: customer|owner|courier, name, phone, address?
/shops/{shopId}                    ownerUid, name/nameAr, logoUrl, address, isOpen, categories[]
/shops/{shopId}/collections/{id}   nameAr, nameEn, sort
/products/{id}                     shopId, priceMinor (int), category, subcategoryId, collectionIds[], stockStatus, isPromo
/orders/{id}                       shopId, customerUid, items[], totalMinor + commission snapshot fields,
                                    status (7-value enum), statusHistory[], driverUid/driverName/driverPhone
/categories/{id}                   seed-managed global taxonomy tree
/areas/{id}                        seed-managed district list (Ismailia/Abu Atwa)
/drivers/{uid}                     isOnline, isSuspended, activeOrdersCount, areaIds[]
/config/platform                   commission bps, delivery fee, driver share (singleton doc)
```

Order status flow: `pending → accepted → preparing → outForDelivery → delivered | cancelled | rejected`
(unchanged since M1). Indexes: `firestore.indexes.json` (several composite indexes for driver
availability + courier order queries).

## Auth & API

- **Auth:** Firebase Auth, email+password (phone OTP deferred). Role chosen at signup, stored on `/users/{uid}.role`. Router (`go_router`) is auth-guarded with role-based redirects (e.g. non-founder bounced off `/finance`).
- **Authorization model:** Firestore security rules per-collection, role-checked via helper functions (`isSignedIn()`, `isFounder()`, owner-of-shop checks, driver-self-write checks). No REST API beyond the Cloudflare Worker's two endpoints (upload, `/notify`).

## Quality: Testing, Performance, Security

- **Testing status:** `flutter_test`, 22 test files, 120/120 passing (unit + widget + bloc tests). i18n parity script enforces 263 matching ar/en keys. Zero on-device E2E runs yet for Marketplace V2 — biggest testing gap.
- **Performance:** Parallel `Future.wait` loads with single BLoC emit (no double-loading flicker) — a Shoppy lesson applied throughout. Firestore aggregate queries (`count()`, `sum()`) used for finance summary instead of document downloads.
- **Security:** Several rules blocks coded but not yet deployed (see Known Issues) — real risk window if a device write test runs before deploy. Money/commission fields are rules-enforced one-way (can't be set early or arbitrarily) to prevent client tampering. No secrets found in tracked files during this scan.

---

> 📄 Maintained by the `ag-project-md` skill. Update it after meaningful changes —
> stale status is worse than no status. Manual edits welcome; the skill preserves them.
