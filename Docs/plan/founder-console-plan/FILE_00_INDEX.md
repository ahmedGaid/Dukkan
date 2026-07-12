# Founder Console Plan — Master Index

> **Load this file first in every session.** Then open the ONE session file you are executing.
> Runs AFTER Phase 6 R0 (full E2E regression) is green. This is roadmap **Phase 7**.

## Project Goal

A complete in-app Back Office so the founder operates the whole platform WITHOUT Firebase
Console, Firestore Console, or the Cloudflare dashboard: real role/permission system (RBAC),
admin API on the existing Cloudflare Worker, desktop-first `/console` area inside the same
Flutter app (runs on Windows/web AND phone), full management verticals (users, shops, products,
taxonomy, geo, orders, drivers, settings, notifications, media, promotions, reports), immutable
audit log, soft delete, impersonation, dev tools. Security enforced server-side (Firestore rules
+ Worker), never by hidden buttons.

## Current state (Deliverables 1–3 of the spec — analyzed 2026-07-12)

**Architecture:** Clean Architecture + BLoC + get_it + go_router. Verticals under
`lib/domain|data|presentation/<feature>/`. Worker at `worker/src/index.js` already verifies
Firebase ID tokens (jose), mints service-account OAuth tokens, reads Firestore via REST, sends
FCM v1, stores images in R2. Pattern to copy for any new vertical: `finance/` (M13).

**Existing admin capabilities:** founder-gated finance page (`/finance`, literal uid in
`AppConfig.founderUid` + `isFounder()` in `firestore.rules`); owner-scoped shop/product/order
management; seed script `lib/dev/seed_demo_data.dart`.

**Operations that require Firebase/Cloudflare console TODAY → session that removes them:**

| Console task today | Removed by |
|---|---|
| Edit `/config/platform` (commission, fees) — `write: false` | 12 |
| Edit `/categories` taxonomy — `write: false` | 09 |
| Edit `/areas` districts — `write: false` | 09 |
| Activate a driver (`isSuspended` flip) | 11 |
| User admin: disable, password reset, email change (Auth console) | 06 |
| Look up a uid (e.g. founder uid for config) | 06 |
| Fix a stuck order (edit status by hand) | 10 |
| Browse/delete R2 images (Cloudflare dash) | 14 |
| Ad-hoc push to users (FCM console) | 13 |
| Re-seed demo data via CLI entrypoint | 15 |

**Stays external (honest limits — cannot move in-app):** deploying `firestore.rules` +
`firestore.indexes.json` (Firebase console/CLI), Crashlytics + Analytics dashboards (link out
from console dashboard), Play Console, Worker deploys (`wrangler deploy`).

## Locked decisions (do not reopen mid-session)

| Decision | Choice |
|---|---|
| Privileged backend | **Extend the existing Cloudflare Worker** with `/admin/*` — NOT Cloud Functions (no Blaze; token verify + service account already proven there) |
| Permission model | Dotted permission strings (`users.read`, `orders.forceStatus`, …) — NEVER `isAdmin` booleans. `Permissions` constants class is the single source of permission names |
| Staff storage | `/admins/{uid}` doc: `role` (`support\|moderator\|admin\|founder`), `permissions` (flat string array, **denormalized by the Worker** from `/roles/{roleId}.permissions` + per-admin extras), `isActive`, `rank` (int; founder=100, admin=80, moderator=60, support=40). `/users.role` keeps its app-persona meaning (customer/owner/courier) untouched |
| Rules check | `hasPerm(p)` helper: `get(/admins/$(request.auth.uid)).data.permissions.hasAny([p, '*'])` + `isActive`. Auth-based only (no `resource.data`) so **aggregate queries keep working** (M13 lesson) |
| Founder bootstrap | `isFounder()` literal uid STAYS in rules as break-glass OR-branch; `/admins/{founderUid}` seeded with `permissions: ['*']`, `rank: 100` |
| Custom claims | NOT used (token-refresh staleness; 1000-byte cap). Doc-based checks everywhere |
| Audit log | `/auditLogs` — client `write: false`; **only the Worker writes** (tamper-proof for Worker-routed ops). Client-direct rule-guarded mutations report via fire-and-forget `POST /admin/audit` — best-effort by nature; therefore every SENSITIVE op is Worker-routed |
| Op routing | Worker-routed (audited server-side): user create/disable/role/email/password, shop ownership transfer, order force-status/reassign, impersonation, broadcast, media delete. Firestore-direct (rules `hasPerm` + best-effort audit): taxonomy, areas, config, flags, product/shop field edits, driver activation |
| Soft delete | `deleted: true`, `deletedAt`, `deletedBy` fields; restore = clear them. NEVER hard-delete business data (only media files + auth accounts on explicit founder action) |
| Console surface | Same Flutter app, `/console` route subtree behind admin guard. Desktop-first (NavigationRail ≥ 900 px, drawer below); ar/en, dark mode, RTL — all existing infrastructure |
| Shop lifecycle | `shops.status`: `pending\|active\|suspended`. **Missing field = active** (back-compat). NEW onboarding creates `pending` → founder approves (behavior change, deliberate) |
| Impersonation | Worker mints TWO custom tokens: target + founder return-ticket (1 h). `signInWithCustomToken` swap; global banner while claim `impersonatedBy` present; exit = sign in with return ticket (expired → login screen). Both events audited. Target with rank ≥ caller forbidden |
| Broadcast | FCM **topics** `role-customer` / `role-owner` / `role-courier` (app subscribes at login by role); Worker sends to topic. No token fan-out |
| Exports | CSV only in v1 (no new deps). Excel/PDF deferred |
| Geo scope | Egypt-only: `/areas` gains `governorate`, `city`, `isActive`, optional `deliveryFeeMinorOverride`. Full country tables = deliberate divergence from spec (YAGNI; expansion is data, not code) |
| Deferred (park, don't build) | image crop/compress, scheduled notifications (optional Task in 13), flash sales/referrals/popups, retention analytics, bulk import |

## Affected files (exhaustive)

- NEW verticals: `lib/{domain,data}/admin/`, `lib/presentation/console/` (shell + one folder per vertical)
- `worker/src/index.js` (route split) + NEW `worker/src/admin.js`
- `firestore.rules` (global helpers + per-collection `hasPerm` branches), `firestore.indexes.json`
- `lib/core/router/app_router.dart` (console subtree + guard), `lib/core/di/injector.dart`
- `lib/core/config/app_config.dart`, `lib/presentation/auth/bloc/auth_bloc.dart` (admin profile)
- `lib/presentation/settings/pages/settings_page.dart` (console entry row)
- `lib/dev/seed_demo_data.dart` (roles/admins seed + reusable `runSeed()`)
- `lib/domain/{shop,product,order,driver,areas,config}/…` — additive fields only
- `lib/l10n/app_ar.arb` + `app_en.arb` (every string, both), `Docs/Brand/BRAND.md` (lexicon rows)

## Never touch

- `lib/core/money.dart` internals; integer piasters everywhere
- The 7-status order enum wire strings (force-status writes existing values only)
- Customer/owner/courier happy paths except the named integration points (shop `status` filter, checkout coupon, home banners)
- `lib/firebase_options.dart`, `android/` signing, existing Worker `/upload` + `/notify` contracts

## Session Map

| # | File | What gets built | Est. |
|---|---|---|---|
| 01 | FILE_01_RBAC_FOUNDATION.md | `/roles` + `/admins`, permissions constants, rules helpers, admin profile in AuthBloc, founder seed | 30 min |
| 02 | FILE_02_WORKER_ADMIN_API.md | Worker `/admin/*` skeleton: perm middleware, Firestore write helpers, audit writer, ping + first endpoint | 30 min |
| 03 | FILE_03_CONSOLE_SHELL.md | `/console` subtree + guard, desktop-first nav shell, permission-driven menu, settings entry | 25 min |
| 04 | FILE_04_AUDIT_LOG.md | Audit vertical: rules, entities, `/admin/audit`, console page with filters | 25 min |
| 05 | FILE_05_DASHBOARD.md | Live-stat dashboard (aggregate queries), recent activity, quick actions | 30 min |
| 06 | FILE_06_USER_MANAGEMENT.md | User list/search/detail, suspend/ban/reset/role via Worker, soft delete | 30 min |
| 07 | FILE_07_SHOP_MANAGEMENT.md | Shop lifecycle (pending/active/suspended), featured/verified, transfer ownership, edit-any | 30 min |
| 08 | FILE_08_PRODUCT_ADMIN.md | Cross-shop product board, edit/soft-delete/restore/duplicate, bulk price/stock/category | 30 min |
| 09 | FILE_09_TAXONOMY_GEO.md | Category/subcategory CRUD console; areas CRUD (governorate/city/active/fee override) | 30 min |
| 10 | FILE_10_ORDER_ADMIN.md | Global order board, staff detail view, force-status + reassign via Worker, internal notes | 30 min |
| 11 | FILE_11_DRIVER_ADMIN.md | Driver activation (!), areas/capacity edit, vehicle/docs fields, performance stats | 25 min |
| 12 | FILE_12_PLATFORM_SETTINGS.md | `/config/platform` + `/config/flags` editors, maintenance mode + min-version gates | 30 min |
| 13 | FILE_13_NOTIFICATION_CENTER.md | Broadcast/targeted push via Worker, topics, history, templates | 30 min |
| 14 | FILE_14_MEDIA_LIBRARY.md | R2 list/preview/delete via Worker, folder filters, orphan finder, storage stats | 30 min |
| 15 | FILE_15_IMPERSONATION_DEVTOOLS.md | Impersonation (custom tokens + banner + audit), dev tools page (seed, fakes, health) | 30 min |
| 16 | FILE_16_PROMOTIONS.md | Coupons + checkout redemption, admin banners on home carousel, featured flags | 30 min |
| 17 | FILE_17_SEARCH_REPORTS_EXPORT.md | Ctrl+K global search, CSV export helper wired into lists, reports page | 30 min |
| 18 | FILE_18_ACCEPTANCE.md | Full acceptance + security verification + regression + sign-off | 30 min |

Dependency spine: 01 → 02 → 03 → 04 → 05; 06–17 each need 01–04 (and 05's tile grid for their
dashboard tiles); 10 needs 11's reassign primitives read; 18 last. Within 06–17 order is
flexible but the written order is the recommended one (pain-first: drivers/settings early
via their prerequisites).

## Ground Rules (every session)

1. **Read before write.** Execute the session's "Before You Start" reads first — no blind edits.
2. **Defense in depth.** Every operation is gated in ALL THREE places it exists: UI (hide/disable),
   Firestore rules (`hasPerm`), Worker (perm middleware). UI alone is NEVER the gate.
3. **Additive & back-compatible.** New doc fields optional-with-default; live docs keep parsing;
   existing wire strings unchanged.
4. **Every mutation audited.** Worker-routed → Worker writes the entry; Firestore-direct →
   fire-and-forget `POST /admin/audit` (same swallow-errors contract as `_notify*`).
5. **i18n parity is build-blocking.** Every user-facing string → key in BOTH ARB files;
   Arabic terms follow `Docs/Brand/BRAND.md` lexicon (add rows there first).
6. **Money = integer piasters, percent = basis points.** Layers: page → BLoC → use case →
   repository → datasource. Tokens only for colors. RTL-first (`EdgeInsetsDirectional`, start/end).
7. **Gates before "done":** `flutter analyze` (0) · `flutter test` (green) ·
   `dart run scripts/check_i18n_parity.dart` · `dukkan-brand` feel check on new UI.
8. **Rules changes are console-deployed by the user** — every session that edits
   `firestore.rules` ends by listing the exact blocks the user must deploy.

## How to use this plan

1. Fresh session → load `FILE_00_INDEX.md` (this file) → open the next unchecked session file.
2. Execute tasks in order, run the smoke test, run the gates.
3. Update the `dukkan-status` skill (position + NEXT ACTION), commit, push, fresh session, next file.

## After all sessions complete

- Run FILE_18 acceptance + security verification on device `R5CNC0NK6ZT` AND a desktop target.
- Extend `Docs/testing/E2E_MASTER_PROMPT.md` with console journeys (J15+).
- Deploy final `firestore.rules` + `firestore.indexes.json` + Worker; re-seed roles.
- Remove `Docs/plan/founder-console-plan` from roadmap NEXT pointers (folder stays as archive).

*Generated by ag-plan skill. Do not edit this index manually.*
