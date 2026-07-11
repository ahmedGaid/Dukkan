# Dukkan — Build Roadmap

> **The single "what next" authority for Dukkan.** Read this before picking any task.
> One session = one session-block below. When a block is done, mark it `[x]`, update the
> `dukkan-status` skill, commit, push, and tell the user to start a FRESH session.

## What Dukkan is

**Dukkan (دكان)** — a two-sided grocery marketplace app for Egypt.
Customers browse nearby shops (دكاكين) and order groceries; shop owners list products and
manage incoming orders. UI/UX inspiration: **Ben Soliman app**
(`com.BenSoliman.BSS` on Play Store) — Arabic retail ordering: promo carousel, category grid,
big product cards with inline add-to-cart, order-tracking stepper.

## North star (bar for every session, added 2026-07-04)

**Premium, easy, clear, minimal — built to become THE brand in this field**, not a generic
clone. Every screen judged against: does this feel premium (not cheap/templated)? Is the flow
obvious with zero explanation? Is every element earning its place — nothing on screen "just
because"? Is it visually distinct enough that someone remembers "Dukkan" specifically? When a
session-block has a UI/UX choice, pick the option that is simpler AND more crafted over the
option that's merely functional or merely decorative — same discipline as Conductor's "would
Linear ship this?", Dukkan's version: **"would this stand out on the Play Store, and would a
دكان owner brag about it?"** Minimal means cut, not shrink — fewer elements, not smaller ones.
Applies on top of the `dukkan-brand` checklist, not instead of it.

## Locked decisions (2026-07-04)

| Decision | Choice |
|---|---|
| Platform | Flutter (Android first, iOS later) |
| Architecture | Clean Architecture (Domain/Data/Presentation) + BLoC + get_it + go_router — proven in Shoppy (`Docs/legacy/`) |
| Backend | Firebase — Auth + Firestore + Storage + FCM. **Active from day 1** (Shoppy lesson: mocked auth caused rework) |
| App split | ONE app, two roles — user picks customer / shop-owner at signup |
| V1 ops | COD only; each shop delivers itself; manual status updates by owner |
| Language | Arabic-first RTL, ar/en parity build-blocking |
| Money | **Integer piasters on the wire** (Shoppy used double — do NOT repeat). Format only at the edge |
| Cart | One cart per shop (v1). Switching shop with items → confirm-and-clear dialog |
| Repo | Private GitHub `ahmedGaid/Dukkan` |
| Brand | Mint green + deep green, rounded type — see `Docs/Brand/BRAND.md` + `dukkan-brand` skill |

## Firestore shape (v1 sketch — refine per session)

```
/users/{uid}       role: 'customer'|'owner'|'courier' (courier = Phase 5), name, phone, address?
/shops/{shopId}/couriers/{uid}   uid, name, phone, joinedAt   (Phase 5 membership)
/shops/{shopId}    ownerUid, name, nameAr, logoUrl, address, isOpen, categories[]
/products/{id}     shopId, name, nameAr, imageUrl, priceMinor (int, piasters),
                   category, stockStatus, isPromo
/orders/{id}       shopId, customerUid, items[], totalMinor, status, createdAt,
                   deliveryAddress, notes?, courierUid? (Phase 5)
```
Status flow: `pending → accepted → preparing → outForDelivery → delivered | cancelled | rejected`

## Phases & sessions

### Phase 0 — Foundation
- [x] **F1 — Scaffold + brand shell.** `flutter create dukkan` (org `com.dukkan`), folder skeleton
      per Clean Architecture, theme from `Docs/Brand/BRAND.md` tokens (AppColors/AppSpacing/AppRadius),
      fonts, logo assets wired, splash screen. Gates green. First push to GitHub.
- [x] **F2 — Core layer + i18n.** DI container, go_router shell, Failure hierarchy, NetworkInfo
      (HTTP probe — NEVER InternetConnectionChecker, Shoppy lesson), `lib/l10n/` ar/en ARB files +
      parity check script (`scripts/check_i18n_parity.dart`), RTL-first MaterialApp.
- [x] **F3 — Firebase + auth + roles.** Firebase project, flutterfire configure, REAL Auth
      (email+password v1; phone OTP deferred — costs money), signup with role choice,
      login/forgot, auth-guarded router, `/users` doc with role. Security rules v1.

### Phase 1 — Customer core
> Before UI sessions: user drops Ben Soliman screenshots into `Docs/ui-ref/` for reference.
- [x] **C1 — Domain + data.** Entities (Shop, Product, CartItem, Order, Address), models,
      Firestore datasources + local cache datasources, repositories, seed script (2 demo shops,
      ~20 products).
- **C2 — Browse.** Split into three build sessions (design direction:
      `Docs/plan/c2-browse-design.md`). Dukkan is a **marketplace** — home leads with shops +
      categories, not products (unlike the single-store Ben Soliman ref).
  - [x] **C2a — UI foundation + Home.** Reusable primitives (AppCard, PriceTag, ShimmerImage,
        EmptyState, GridShimmer, StatusChip, bottom-nav shell) + Home (promo carousel + category
        grid + nearby-shops list) + ShopsBloc. All states designed.
  - [x] **C2b — Shop + products.** Shop page (header w/ open/closed, in-shop category filter),
        product grid, product detail. ProductsBloc.
  - [x] **C2c — Search + polish.** Global product search (matches product name/category + shop
        name, Arabic-folded, debounced); designed prompt/no-results/error/loading states. SearchBloc.
- [x] **C3 — Cart + checkout.** Per-shop cart, quantity stepper, checkout with manual address
      entry (maps deferred), COD confirm, order placed screen.
- [x] **C4 — Orders.** Orders list, order detail with status stepper, cancel
      (pending/accepted only), realtime status via Firestore snapshots.

### Phase 2 — Shop owner core
- **S1 — Shop onboarding.** Owner signup flow → create shop profile (name ar/en, logo upload,
      address, open/closed toggle). Storage backend = **Cloudflare R2** via a Worker (app never
      holds R2 keys). Split:
  - [x] **S1a — Storage foundation.** `worker/` (Cloudflare Worker verifying Firebase ID token →
        R2 put) + Flutter `StorageRepository`/`UploadImage`/R2 upload datasource (dart:io, no new
        dep) + `AppConfig.uploadWorkerBaseUrl` (stubbed till deploy) + tests. Gates green.
  - [x] **S1b — Onboarding UI.** Owner signup → shop-profile form → `image_picker` logo → upload
        via the S1a foundation → save `/shops` doc. Needs Firestore `/shops` owner-write rule.
- [x] **S2 — Catalog manager.** Product CRUD, image upload, price (piasters!), stock toggle,
      promo flag.
- [x] **S3 — Order desk.** Incoming orders list (realtime), accept/reject, advance status,
      daily summary strip.

### Phase 3 — Polish
- [x] **P1 — Favorites + promos + states pass.** Favorite shops/products, promo carousel wired to
      real promo flags, full empty/error-state audit.
- **P2 — Notifications + settings.** Split (2026-07-05 — FCM needs new deps + a backend sender
      / Blaze, and can't be verified without a wired device; settings + dark-mode need none of that):
  - [x] **P2a — Settings + dark-mode audit.** Settings page (profile, language, theme mode, logout,
        version) + dark-mode audit against `logo-dark.png` palette. No new deps.
  - [x] **P2b — Notifications (FCM).** Push (order status → customer, new order → owner). Sender
        backend = the existing Cloudflare Worker, extended with `/notify` (FCM HTTP v1).
- [x] **P3 — Ratings.** Shop rating after delivered order, average on shop card.

### Phase 4 — Release
> **R0 moved (2026-07-11, user decision):** the full E2E regression now runs ONCE at the END of
> the whole plan (after M14) as the final gate — see Phase 6 below. A partial R0 already ran
> (report: `Docs/testing/e2e-reports/2026-07-11/report.md` — Phase 0 + S1 pass, J1 auth-race fix
> `ef32ae4` still unverified on device); its findings carry into the final run.
- [~] **R1 — Store prep.** Adaptive icon + splash from logo **DONE** (white minimal tile,
      D+awning mark auto-extracted; `flutter_launcher_icons` + `flutter_native_splash` wired).
      Arabic + English store listing copy **DONE** (`Docs/RELEASE_LISTING.md`).
      **Screenshots + feature graphic still pending** — need the app running with seeded data
      (blocked on Firestore `(default)` DB). Capture list is in RELEASE_LISTING.md.
- [x] **R1b — Official icon pack swap (added 2026-07-10, DONE 2026-07-10).** User delivered the
      OFFICIAL multi-platform logo pack at **`Dukkan Logo Assets/`** (repo root):
      `Android/` adaptive foreground+background 432 + legacy 48–192 · `iOS/` 40–1024 ·
      `Web/` favicons 16–48 + apple-touch-180 + social-avatar-512 ·
      `Mark-Transparent/` light+dark marks 128–1024. It SUPERSEDES the R1 auto-extracted mark.
      Do: point `flutter_launcher_icons` at `Android/adaptive-foreground-432.png` +
      `adaptive-background-432.png` (+ legacy fallback), regenerate; regenerate splash from
      `Mark-Transparent/dukkan-mark-light-1024.png` (dark variant from `-dark-`); replace
      `assets/brand/` marks with the official transparent marks; keep iOS/ + Web/ staged for
      later iOS build + any web/social surface. Rebuild on device, eyeball launcher + splash
      light/dark. Gates green.
- [~] **R2 — Ship.** Crashlytics **wired** (`2f00847` — dep + Gradle plugins + error routing;
      release AAB builds clean; live-event verify needs device). Release signing config wired
      (`4d3d22b`). Remaining: user generates keystore (`Docs/RELEASE.md` §1), on-device
      Crashlytics event check, Play internal-track upload.

### Phase 5 — Marketplace V2 — added 2026-07-11, runs after R2
> **Replaces the 2026-07-10 courier-role phase** — decision: shared platform driver pool instead
> of shop-owned couriers (`courier-role-plan/` stamped SUPERSEDED by session M8). Five features:
> owner order details + status timeline · seed-managed global taxonomy · shop collections + home
> chips carry-over · shared drivers (Ismailia areas, capacity, transaction assignment, courier
> shell مندوب التوصيل) · commission ledger + founder finance page. 7-status enum UNCHANGED.
> **Session authority: `Docs/plan/marketplace-v2-plan/` — load `FILE_00_INDEX.md` first, then
> one FILE_NN per session (M1–M14 = FILE_01–FILE_14).**
- [x] **M1–M2 — Order details.** M1 **DONE** — `statusHistory` log: `StatusChange` entity,
      `Order.statusHistory` field, model parse/serialize, datasource appends on create + every
      transition (`FieldValue.arrayUnion`, `currentUid` from injected `FirebaseAuth`), rules allow
      `statusHistory` alongside `status`. **M2 DONE** — one role-aware `OrderDetailPage` (owner
      flag via `/order/:id?owner=true`, set from `order_desk_page.dart`'s now-tappable
      `_OwnerOrderCard`): owner-only customer name/phone card (fetched via new
      `AuthRepository.getUserById`/`GetUserById` use case, no new dep — phone is selectable text,
      no `url_launcher`), payment-method + subtotal/delivery-fee/total card, a `driverUid`-gated
      placeholder card (field added to `Order`/`OrderModel`, always null until M9 wires it), and
      an `_OrderTimeline` (both roles) rendering `statusHistory` oldest-first with a single-row
      fallback for pre-M1 orders. Gates green (analyze 0, test 58/58, parity 202). Two new lexicon
      rows added (`BRAND.md`): "Order history/timeline" → سجل الطلب, "Driver" → المندوب. Device
      smoke test (both M1 and M2) still pending — no device connected this session; **the M1
      `firestore.rules` update (statusHistory in the update diff whitelist) is also still
      undeployed** — deploy via Firebase console before any real order write is tested on device,
      or status/statusHistory writes will be rejected by the currently-live (pre-M1) rules.
- [x] **M3–M5 — Taxonomy + browse.** Done in one combined session (FILE_03+04+05), code-only.
      **M3**: `/categories` seed-managed tree (`lib/domain/taxonomy/`, `lib/data/taxonomy/`) — 7
      top-level categories using the SAME Arabic strings already live as `Shop.categories`/
      `Product.category` (not the plan doc's generic example names) so old filtering keeps
      matching with no translation table; `Product.subcategoryId` (nullable) added + assigned to
      all 53 seeded products; `firestore.rules` `/categories` read-signed-in/write-false (note:
      the dev seed script's `_seedTaxonomy()` needs that `false` temporarily relaxed to
      `isSignedIn()` for one re-seed pass, then restored — rules writes are console-deployed by
      the user anyway, same as the still-undeployed M1 rule). Lexicon: Category → القسم,
      Subcategory → القسم الفرعي. **M4**: product form's free-text category field replaced with
      dependent category→subcategory `DropdownButtonFormField`s (taxonomy loaded via
      `FutureBuilder`, no bloc — matches the page's existing style), validation, submit writes
      `subcategoryId` + derived `category`. **M5**: kept the home page's existing 3-col
      `CategoryGrid` (deliberate C2a design choice, more distinctive than a generic chip row —
      diverged from FILE_05's literal "chip row" wording) and added a settled 200ms select
      animation; selected category now carried as router `extra` into `ShopPage` →
      `ProductsBloc(initialCategory: ...)`, applied once on the catalog's first arrival. Existing
      `productsCategoryEmptyTitle/Body` empty state reused instead of FILE_05's near-duplicate
      MSA-register strings (voice consistency). Gates green (analyze 0, test 68/68, parity 206).
      Device smoke test (re-seed + dropdown + carried-filter checks) still pending — no device
      this session.
- [x] **M6–M7 — Collections.** Done in one combined session (FILE_06+07), code-only.
      **M6**: `/shops/{shopId}/collections/{id}` (`lib/domain/collections/`,
      `lib/data/collections/`) — `ShopCollection` entity (id, nameAr, nameEn, sort);
      `CollectionsRepository` with both `watchCollections` (realtime, owner manager +
      customer shop page) and `getCollections` (one-shot, product form picker — spec's
      literal "watch/get(shopId)"); `firestore.rules` nested `/collections` match under
      `/shops/{shopId}` (read any signed-in user, write shop-owner-only, mirrors the
      parent shop's owner check). Owner manager page (`collections_manager_page.dart`,
      reached via a new AppBar icon on `catalog_manager_page.dart`) — list, create/rename
      bottom sheet (two required name fields + a static "e.g. عروض/Offers" placeholder),
      delete confirm (exact spec copy "Deleting the collection keeps the products").
      `CollectionsBloc` follows `OrderDetailBloc`'s cancel/rate shape: the sheet/dialog
      closes optimistically, a submitting→failure transition snackbars once
      (blame-free "حصلت مشكلة — جرّب تاني"), success needs no local flag since the
      realtime stream reflects it. **M7**: `Product.collectionIds` (nullable-safe empty
      list, old docs parse fine) threaded through model/datasource/repository/
      `CreateProduct`; product form's `_CollectionsPicker` (multi-select `FilterChip`s,
      one-shot `GetCollections` load, hides entirely for a shop with no collections OR
      on a load error — optional secondary field, never worth blocking the form);
      `ProductsBloc` gained a third stream (`WatchCollections`, non-critical — a failure
      is swallowed, never surfaces as page-level error) plus `selectedCollectionId`,
      combined with the existing category filter via AND in `visibleProducts`; a second
      chip row on `shop_page.dart` (no "All" chip — tap-again-clears, unlike the
      category row) with the same stale-selection safety as categories (a deleted
      collection drops the filter, no crash). Lexicon: Collection → مجموعة
      (`BRAND.md`). Gates green (analyze 0, test 85/85, parity 221 — up from 206;
      +collections_bloc_test.dart, +collections_model_test.dart, product/products-bloc
      tests extended). Device smoke test (both sessions' full lists in FILE_06/07) still
      pending — no device this session; the new `/collections` rules block is also
      still undeployed alongside the earlier M1/M3 rules.
- [ ] **M8–M11 — Drivers.** Areas + driver profiles (suspended-by-default), assignment
      transaction + owner sheet, courier shell, assignment push + regression matrix.
      **M8 DONE 2026-07-11** (`FILE_08_AREAS_DRIVERS.md`), code-only — `courier-role-plan/`
      stamped SUPERSEDED; `UserRole.courier` end-to-end (signup card, `/users` role, router
      redirect to a placeholder `CourierHomeShell` with a designed "coming soon" deliveries tab +
      shared Settings tab, so a courier can still switch language/log out); `/areas` seed-managed
      district list (`lib/domain/areas/`, `lib/data/areas/`, mirrors taxonomy's one-shot +
      local-cache pattern) — 5 Ismailia/Abu Atwa districts matching where the real seeded shops
      sit; `Address.areaId` (nullable) threaded through `Order`/`OrderModel`, checkout's new
      required area dropdown (mirrors product-form's taxonomy dropdown); `/drivers/{uid}` profile
      (`lib/domain/driver/`, `lib/data/driver/`) — `createDriverProfile` fires from `AuthBloc`
      right after a courier signup, suspended by default; `firestore.rules` `/areas` +
      `/drivers` blocks (driver self-writes only `isOnline`/name/phone; owners get read for the
      Session 9 assignment list); composite index for the `areaIds array-contains + isOnline +
      isSuspended` availability query; seed script writes 5 areas + 2 demo drivers (one
      active, one suspended) — same temporarily-relax-rules-then-restore trick as taxonomy.
      Gates green (analyze 0, test 92/92, parity 229 — up from 221). Device smoke test (courier
      signup → suspended `/drivers` doc → placeholder shell; checkout area dropdown; own-`isOnline`
      write allowed, `isSuspended` write denied; `availableDrivers('abu-atwa')` returns the active
      seed driver only) still pending — no device this session; the new `/areas` + `/drivers`
      rules blocks are also still undeployed alongside the earlier M1/M3/M6 rules. **Next: M9
      (`FILE_09_ASSIGNMENT_TXN.md`) — assignment transaction + owner "assign driver" sheet.**
- [ ] **M12–M13 — Commission.** `/config/platform`, order snapshot (bps/piasters, round-half-up),
      payable-at-delivered, founder-gated finance summary (aggregate queries).
- [ ] **M14 — Acceptance.** Full acceptance + regression sign-off.

### Phase 6 — Final gate (moved here from Phase 4 on 2026-07-11)
- [ ] **R0 — Full E2E regression.** Run `Docs/testing/E2E_MASTER_PROMPT.md` end to end on the
      real device (customer + owner + courier journeys, four-layer verification, fix loop) —
      the last block of the whole plan. Must be GREEN (or GREEN-WITH-SKIPS with only
      human-blocked items). Carry-over from the 2026-07-11 partial run: re-verify the `ef32ae4`
      auth-race fix (fresh signup → Settings shows the entered name, not the email) and Phase 4
      of the master prompt must add journeys for everything M1–M14 shipped.

## Standing regression (added 2026-07-10)

`Docs/testing/E2E_MASTER_PROMPT.md` is the master daily E2E test prompt (same pattern as
Conductor's). Self-maintaining: every run adds journeys for newly shipped features. After the
final R0 it runs daily (scheduled agent) and before every release build. Reports land in
`Docs/testing/e2e-reports/YYYY-MM-DD/`.

## Session protocol (same as Conductor)

1. Fresh session → invoke `dukkan-resume` (reads `dukkan-status` + this file).
2. Do ONE session-block. Run gates before "done":
   `flutter analyze` · `flutter test` · `dart run scripts/check_i18n_parity.dart` (once it exists).
3. Update `dukkan-status` skill (position, NEXT ACTION, blockers).
4. Commit + push. Report with **How to test**. Tell user: clear session, start fresh.
5. Blocked? Write the blocker into `dukkan-status`, stop, ask.

## Shoppy lessons (do not re-learn — full list `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` §11)

- HTTP probe for connectivity, not socket checkers (firewalled on Android).
- No cache TTL games — `online → remote, offline → local cache`, cache after fetch.
- Parallel `Future.wait` loads, single emit — no double-Loading flicker.
- Optimistic list updates after place/cancel — no reload flash.
- Cart badge = distinct products (`items.length`), never total quantity.
- Local datasource seed guard (`_ready` future awaited by every method).
