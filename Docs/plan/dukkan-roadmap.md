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
- [x] **M8–M11 — Drivers.** Areas + driver profiles (suspended-by-default), assignment
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
      rules blocks are also still undeployed alongside the earlier M1/M3/M6 rules.
      **M9 DONE 2026-07-11** (`FILE_09_ASSIGNMENT_TXN.md`), code-only — `Order` gained
      `driverName`/`driverPhone`/`assignedAt` (denormalized at assignment, nullable, old
      docs parse); `DriverRemoteDataSource.assignDriver` runs the capacity/area/status/
      online/taken validation transaction (`DriverUnavailable` failure + reason enum),
      `OrderRemoteDataSource._advanceStatus` decrements `activeOrdersCount` (floor 0) in
      the same transaction as any delivered/cancelled/rejected write; `firestore.rules`
      lets any signed-in user bump `drivers/{uid}.activeOrdersCount` by exactly ±1 and
      lets the shop owner set the order's driver-block fields once, while
      accepted/preparing and unassigned (deliberately loose — comment flags a Worker
      endpoint as the future hardening path, same pattern as M8); owner order-details page
      now shows an "assign courier" sheet (`assign_driver_sheet.dart`, `FutureBuilder`
      over `Future.wait([availableDrivers, GetAreas])`, client-side capacity filter,
      designed empty state, confirm dialog, reason-specific snackbar) when
      accepted/preparing with no driver, and a driver-info card (name/phone/assigned
      time) to BOTH owner and customer once assigned. Gates green (analyze 0, test 96/96
      — up from 92, parity 241 — up from 229). Device smoke test (race two owners for a
      driver's last slot, offline/capacity/area rejections, decrement on delivery) still
      pending — no device this session; the new order-driver-field + drivers-count rules
      are also still undeployed alongside M1/M3/M6/M8.
      **M10 DONE 2026-07-11** (`FILE_10_COURIER_SHELL.md`), code-only —
      `OrderRepository` gained `watchDriverActiveOrders` (driverUid +
      preparing/outForDelivery, unordered — sorted client-side) and
      `watchDriverHistory` (driverUid + delivered, newest first, capped at
      20); two new composite indexes; `firestore.rules` lets the assigned
      driver read their own orders and make exactly the two transitions
      (preparing→outForDelivery, outForDelivery→delivered). `OrderDetailPage`/
      `OrderDetailBloc` widened from a bool `isOwner` to an `OrderViewerRole`
      enum (customer/owner/courier) instead of a new duplicate detail page —
      courier view reuses the M2 customer-contact card (renamed
      `_CustomerContactCard`), adds an area-name line to the address card
      (one-shot `GetAreas` lookup, display-only) and a bottom "Picked
      up"/"Delivered" action (own courier-facing copy, `courierPrimaryAction`
      in `order_status_view.dart`; delivered confirms, picked-up doesn't;
      reuses the same `UpdateOrderStatus` path as the owner desk, so
      `statusHistory` records the courier's uid for free). New
      `DeliveriesBloc` (two realtime subscriptions + a one-shot area list)
      drives the courier shell's real deliveries tab (replacing the Session 8
      placeholder): online/offline switch, suspended banner, Active/History
      segmented list, cards with shop name (per-card one-shot `WatchShop`
      lookup) + area + item count + total. Lexicon: courier pickup/delivered
      copy + online/offline. Gates green (analyze 0, test 104/104 — up from
      96, parity 250 — up from 241). Device smoke test (full list in
      FILE_10) still pending — no device this session; the new order-driver
      read/transition rules are also still undeployed alongside
      M1/M3/M6/M8/M9.
      **M11 DONE 2026-07-11** (`FILE_11_DRIVER_NOTIFY.md`), code-only —
      `NotificationEventType` gained `driverAssigned`; Worker's `/notify`
      handler accepts it (`NOTIFY_TYPES`), split the caller-check into
      three explicit branches (was `if newOrder / else statusUpdate`,
      which would have silently applied the owner→customer statusUpdate
      rule to the new type) — `driverAssigned` requires caller ==
      `shop.ownerUid`, target = `order.driverUid`; the courier uid can't
      trigger `newOrder`/`statusUpdate` since neither's caller check can
      match it. App: `assign_driver_sheet.dart`'s `_confirmAndAssign` fires
      the push right after a successful `AssignDriver` call (fire-and-forget,
      same pattern as `_notifyCustomer`/`_notifyShopOwner`) — one-shot
      `WatchShop` lookup for the shop name, the already-loaded area list for
      the area name (both bilingual, both null-safe if either lookup comes
      back empty). Lexicon: notifyDriverAssignedTitle/Body (`ar.json`/
      `en.json`). Skipped the plan's optional `orderDelivered` (owner
      notified on courier completion) — same trivial pattern, but out of
      this session's scope, no restructuring blocker.
      **`orderDelivered` added 2026-07-12** (device-free follow-up while
      R0 waits on Worker/rules deploy) — `NotificationEventType.
      orderDelivered` (`'orderDelivered'` wire), Worker `/notify` branch
      (caller must be the order's `driverUid`, target = `shop.ownerUid`,
      mirror of `driverAssigned`'s reverse direction), fired from
      `OrderDetailBloc._onAdvanceRequested` right after a successful
      courier `delivered` transition (new optional `NotifyOrderEvent?`
      constructor param, wired in `injector.dart`) — bilingual
      fire-and-forget, same swallow-errors contract as the other
      `_notify*` call sites. Lexicon: notifyOrderDeliveredTitle/Body
      (ar/en, reuses existing "delivered" vocabulary, no new lexicon row
      needed). Gates green (analyze 0, test 120/120 — up from 118, parity
      263 — up from 261). Device verification rides the same Phase 6 R0
      session as the rest of Marketplace V2 pushes. Task C (device
      regression matrix: no-driver order,
      driver order full flow, owner-cancels-after-assignment, customer-
      cancels-pending) deferred — no device this session, same as
      M8/M9/M10; Worker deploy + rules deploy (dukkan-status blockers 1–2)
      still pending so live push delivery is also unverified — request-side
      code is in place and unit-provable by inspection only. **Phase 5
      Drivers (M8–M11) code-complete. Next: M12–M13 — Commission
      (`FILE_12_COMMISSION_LEDGER.md`).**
- [x] **M12–M13 — Commission.** `/config/platform`, order snapshot (bps/piasters, round-half-up),
      payable-at-delivered, founder-gated finance summary (aggregate queries).
      **M12 DONE 2026-07-12** (`FILE_12_COMMISSION_LEDGER.md`), code-only —
      `PlatformConfig` entity/repo (new `lib/domain/config`, `lib/data/config`,
      memoized per app session, no offline branch — same one-shot contract as
      `AreasRepository`) + `/config/platform` seeded (5% commission, 30 EGP
      delivery fee, 25 EGP driver share). `Order` gained 7 snapshot fields
      (subtotalMinor/deliveryFeeMinor/commissionBps/commissionMinor/
      driverDeliveryShareMinor/platformDeliveryShareMinor/commissionPayable),
      all optional-with-default; `subtotalMinor` falls back to `totalMinor`
      in the entity constructor itself (`subtotalMinor ?? totalMinor`) so
      every old seeded/pre-M12 doc parses without a special case in
      `OrderModel`. `PlaceOrder` no longer takes a caller-supplied
      `totalMinor` — it derives subtotal from `items` itself and snapshots
      the config at creation time (round-half-up: `(subtotal * bps + 5000)
      ~/ 10000`), so a stale/tampered client total can never land on the
      doc; `OrderRepository.placeOrder`/datasource/checkout_page updated to
      match. Payable flip lives in `OrderRemoteDataSource._advanceStatus`'s
      existing terminal-status transaction (delivered only) — covers both
      the owner and the assigned-driver delivery paths since both call the
      same method. `firestore.rules`: new `/config/{docId}` (read-only,
      same shape as `/areas`) + a `isDeliveredCommissionFlip()` helper so
      the owner-transition and driver-transition update branches both allow
      `commissionPayable` in the diffed keys ONLY when flipping to
      `delivered` and only to `true` — can't be set early or arbitrarily.
      Checkout summary and the owner order-detail payment card now show the
      real subtotal/fee/total (both reused existing l10n keys, no new
      strings). Gates green (analyze 0, test 110/110 — up from 104, added
      commission-rounding + fromFirestore-fallback tests; parity 252,
      unchanged). Four pre-existing test fakes (`_FakeOrderRepository` in
      deliveries/order_detail/orders/owner_orders_bloc_test.dart) updated to
      the new `placeOrder` signature — no behavior change, override-shape
      only.
      **M13 DONE 2026-07-12** (`FILE_13_FINANCE_SUMMARY.md`), code-only —
      new `lib/domain/finance` + `lib/data/finance` vertical (`FinanceSummary`
      entity with a derived `platformRevenueMinor` getter, `FinanceRepository`/
      `FinanceRepositoryImpl` — no cache, always a fresh read) backed by
      `FinanceRemoteDataSource.getSummary()`: three Firestore round trips
      (`orders.count()`, a combined `delivered.aggregate(count(), sum(
      commissionMinor), sum(platformDeliveryShareMinor))`, and `cancelled/
      rejected.count()`) run via `Future.wait`, no document downloads.
      `AppConfig.founderUid` const (verified against the Firebase console
      value for `ahmedgaid14@gmail.com`) gates a hidden settings row
      (`_FinanceRow`, only built when `user.uid == founderUid`) and the new
      `/finance` route, which the router's `_redirect` also bounces to
      `/home` for anyone else who lands on it directly. `firestore.rules`'
      `/orders` read rule gained an `isFounder()` branch — deliberately
      `resource.data`-independent (OR'd first) since Firestore only permits
      an aggregation query when the rule can be satisfied without reading
      per-document data. `FinancePage` (calm monochrome per the north star —
      no accent colour, unlike `_DailySummaryStrip`'s green totals): a ledger
      disclaimer line, a 2-column grid of six stat tiles (three counts, three
      money via `PriceTag` recoloured to `onSurface`), `GridShimmer` loading,
      designed error+retry, `RefreshIndicator` pull-to-refresh via
      `FinanceBloc`'s single load event reused for both start and refresh.
      RTL note: the settings row's chevron picks `chevron_left`/`chevron_right`
      by `Directionality` (the `Icon.matchTextDirection` param doesn't exist —
      that flag lives on `IconData`, not the widget). New lexicon row
      (`BRAND.md`): Finance → المالية. Gates green (analyze 0, test 118/118 —
      up from 110, added finance_bloc_test.dart + finance_summary_test.dart;
      parity 261 — up from 252). Smoke test (founder sees the row and real
      numbers, non-founder direct-route bounce, rules-deny for non-founder
      aggregate reads) still pending — no device this session, same as
      M8–M12; the new `/orders` rules branch is also still undeployed
      alongside M1/M3/M6/M8–M12. **Next: M14 — Acceptance.**
- [ ] **M14 — Acceptance.** Full acceptance + regression sign-off.
      **Code-only portion DONE 2026-07-12** (`FILE_14_ACCEPTANCE.md`) — gates green
      (analyze 0, test 118/118, parity 261, unchanged this session), confirmed
      `core/money.dart` and the 7-status enum untouched since M1–M13, confirmed
      the driver/category/subcategory/collection Arabic terms are each one
      canonical word in `Docs/Brand/BRAND.md`, added J13 (drivers) + J14
      (commission/finance) journeys to `E2E_MASTER_PROMPT.md` Phase 2.
      **Still pending (device, on `R5CNC0NK6ZT`):** the on-device acceptance
      checklist A–E in `FILE_14_ACCEPTANCE.md` (order details/history, taxonomy,
      collections/chips, drivers, commission), the v1 regression checklist, the
      micro-polish pass, and rules/index deploy verification — all folded into
      **Phase 6 R0** below since that's the same device session. M14 sign-off
      closes only after R0 runs green.

### Phase 6 — Final gate (moved here from Phase 4 on 2026-07-11)
- [ ] **R0 — Full E2E regression.** Run `Docs/testing/E2E_MASTER_PROMPT.md` end to end on the
      real device (customer + owner + courier journeys, four-layer verification, fix loop) —
      the last block of the whole plan. Must be GREEN (or GREEN-WITH-SKIPS with only
      human-blocked items). Carry-over from the 2026-07-11 partial run: re-verify the `ef32ae4`
      auth-race fix (fresh signup → Settings shows the entered name, not the email) and Phase 4
      of the master prompt must add journeys for everything M1–M14 shipped.

### Phase 7 — Founder Console (planned 2026-07-12, runs after Phase 6 R0 is green)
> Complete in-app Back Office: RBAC (permission strings, `/admins` + `/roles`), admin API on
> the existing Cloudflare Worker (`/admin/*`), desktop-first `/console` area, management
> verticals (users, shops, products, taxonomy, geo, orders, drivers, settings, notifications,
> media, promotions, reports), immutable audit log, soft delete, impersonation, dev tools.
> Kills the recurring Firebase-console chores (config/taxonomy/areas edits, driver activation,
> user admin). **Session authority: `Docs/plan/founder-console-plan/` — load `FILE_00_INDEX.md`
> first, then one FILE_NN per session (18 sessions).**
- [~] **FC1–FC5 — Foundation.** RBAC + rules helpers · Worker admin API + audit writer ·
      console shell + guard · audit log vertical · live dashboard. (FILE_01–05)
      **FC1 DONE (code) 2026-07-12** — `lib/{domain,data}/admin/` (Permissions, StaffRole,
      AdminProfile + fail-closed model, memoized AdminRepository+reset, Get/ResetAdminProfile),
      AuthBloc staff-profile load → `AuthState.adminProfile`/`can()`, `/finance` router+settings
      gates on `can(financeRead)` (founder-uid break-glass kept), seed `_seedRbac` (4 roles +
      founder `/admins`), `firestore.rules` `hasPerm`/`isStaff` helpers + `/admins`+`/roles` +
      extended `/orders`,`/users` reads. Gates green (analyze 0, test 132, parity 263). Rules
      UNDEPLOYED.
      **FC2 DONE (code) 2026-07-12** — Worker `/admin/*`: `worker/src/firebase.js` (shared
      plumbing extracted from `index.js` + `firestoreCreateDoc`/`PatchFields`/`Commit` write
      helpers + generalized `to/fromFirestoreFields` type conversion + `identitytoolkit` scope),
      `worker/src/admin.js` (fail-closed `requireAdmin` perm middleware, `writeAudit`, `/admin/ping`
      + `/admin/audit`), `index.js` `/admin/` dispatch (upload/notify unchanged), Flutter
      `AdminApiDataSource` (post + fire-and-forget `reportAudit`) registered in injector. Gates
      green (analyze 0, test 132, parity 263). No rules change this session; Worker deploy owed
      (user).
      **FC3 DONE (code) 2026-07-13** — `/console` ShellRoute + admin guard in `app_router.dart`
      (any active staff enters; non-staff bounced `/home`), `lib/presentation/console/shell/`
      (`console_sections.dart` = `ConsoleSection` registry + pure `visibleConsoleSections` filter;
      `console_shell.dart` = desktop-first `NavigationRail` ≥900px / `Drawer` below, top-bar section
      title + staff chip, Ctrl+K `ConsoleSearchIntent` placeholder unmapped till FC17),
      `console/dashboard/pages/dashboard_page.dart` (designed EmptyState placeholder, FC5 fills),
      `_ConsoleRow` in settings (active-staff only). Registry seeds dashboard + audit; audit routes
      to an EmptyState placeholder until FC4. 10 i18n keys ×2 + lexicon rows (Console→لوحة التحكم,
      Founder→المؤسس). No rules/Worker change. Gates green (analyze 0, test 138, parity 273).
      **FC4 DONE (code) 2026-07-13** — audit log vertical (FILE_04). `firestore.rules`
      `/auditLogs` block (`read: hasPerm('auditlogs.read')`, `write: false` — Worker-only,
      immutable) + 4 `auditLogs` composite indexes (targetType/actorUid/action/targetId ×
      createdAt desc). `lib/{domain,data}/audit/` — `AuditEntry`/`AuditFilter`/`AuditPage`/
      `AuditActions`, `AuditRepository`+`GetAuditEntries`, `AuditEntryModel.fromFirestore`
      (fail-soft, ISO createdAt), `AuditRemoteDataSource` (filter→query, value-cursor pagination
      by createdAt — no `DocumentSnapshot` in domain, page 30), no-cache repo (mirrors Finance).
      `lib/presentation/console/audit/` — `AuditLogBloc` (load/filter/loadMore) + page: filter bar
      (action/type/targetId/date-range + clear), designed loading/empty/error states, paginated
      list (auto + Load-more + pull-refresh), row (target icon, action, actor, relative time,
      «مُبلَّغ» chip when reported), detail sheet (kv + before/after diff table). Router placeholder
      → `AuditLogPage`; **router guard now enforces per-section `requiredPerm`** (deep-link to a
      section a staff member lacks bounces to `/console`) via new pure `consoleSectionForLocation`.
      27 i18n keys ×2 (first ICU placeholders in the project: relative-time counts) + lexicon row
      (Activity/audit log→سجل العمليات). Gates green (analyze 0, test 151, parity 298). **Rules +
      indexes UNDEPLOYED (user).**
      **FC5 DONE (code) 2026-07-13** — live dashboard (FILE_05), fills the FC3 `/console`
      EmptyState placeholder. `lib/{domain,data}/dashboard/` — `DashboardSummary`
      (+`DailyOrderCount`), `DashboardRepository`+`GetDashboardSummary`, `DashboardRemoteDataSource`
      (one parallel `Future.wait` of `count()`/`sum()` aggregates over orders/shops/products/
      drivers/users — no doc downloads; auth-only read rules keep aggregation legal), pure
      DST-safe `day_window.dart` (local-midnight windows), no-cache repo (mirrors Finance). Nine
      stat tiles: orders/revenue/commission today, orders waiting, users, shops, products, drivers
      online, pending shops. `DashboardBloc` (page-scoped, 60s silent auto-refresh + pull-refresh,
      single-emit) — **permission-gated**: viewer perms arrive on the start event from the page's
      AuthBloc; `users.read` gates the users count (else tile shows «—»), `auditlogs.read` gates the
      recent-activity strip (moderator/support lack it → hidden, no permission-denied). Page:
      responsive 2/4-col grid, `MiniBarChart` CustomPaint 7-day bars (no new dep, weekday initials,
      today accent), recent-activity card (last 10 audit entries via FC4 repo, tap→`/console/audit`),
      audit quick-action chip, external-tools Crashlytics row (selectable URL, no url_launcher).
      Shared `console/widgets/stat_tile.dart` extracted from FinancePage's tile (both now reuse it).
      **+1 composite index** `orders: status + createdAt` (delivered-today sums). 19 i18n keys ×2 +
      lexicon (Shops→الدكاكين, Drivers→مناديب). Gates green (analyze 0, test 161, parity 317).
      **Rules + indexes deployed 2026-07-13** (`firebase deploy --only firestore:rules,firestore:indexes`,
      project `dukkan-93042`). Device E2E still owed (RBAC unseeded on device — reseed pending).
- [~] **FC6–FC11 — Management verticals.** Users (Auth ops via Worker) · shops (lifecycle,
      transfer) · products (bulk ops) · taxonomy+geo (console-editable) · orders
      (force-status, reassign, notes) · drivers (activation!). (FILE_06–11)
      **FC6 DONE (code) 2026-07-13** — user management (FILE_06). Worker `/admin/users/*`
      (set-disabled w/ Auth `disableUser`+`validSince` session revoke, set-persona-role,
      change-email, soft-delete/restore, create, lookup via Identity Toolkit REST) +
      `/admin/admins/*` (set/remove, rank-guarded: caller must outrank both the target's
      current AND new rank — blocks touching/creating a second founder). `firebase.js` gained
      `identityToolkitCall`, `firestoreDeleteDoc`, `fsTimestamp` (Worker-created docs now stamp
      a real Firestore Timestamp, matching client `serverTimestamp()` docs — no string/Timestamp
      split). `firestore.rules` `/users` update gained a narrow `hasPerm('users.update')` branch
      (name/phone/status/deleted* fields only; role/email stay Worker-only). `lib/domain/admin/` —
      `ManagedUser`/`AuthLookup`/`UsersPage` entities, `AdminUserActions` (9 Worker-routed
      mutations) + `AdminUsersRepository` (no-cache, paginated by `FieldPath.documentId` — never
      `createdAt`, whose type can differ on legacy docs) with 11 thin usecases, plus
      `GetStaffProfileForUid` (unmemoized — reads an arbitrary uid's `/admins` doc without
      touching the signed-in session's single-slot cache). `lib/presentation/console/users/` —
      `UsersBloc` (paginated list, role/status filters, exact email/phone search else page-local
      name filter, multi-select bulk suspend/unsuspend) + `UserDetailBloc` (profile/auth/staff
      panels, every mutation re-syncs via `getByEmail` since there's no get-by-uid) and their two
      pages (`/console/users`, `/console/users/:uid` — reached only via the list row's `extra`
      seed). Staff role/extra-permissions editor reuses `StaffRole`/`Permissions.values` (no new
      `/roles` read). 61 i18n keys ×2 + lexicon (Suspend→إيقاف مؤقت, Ban→حظر, Restore→استرجاع) +
      `actionConfirm`/`consoleNavUsers`. Added `users_bloc_test.dart` (9 cases),
      `user_detail_bloc_test.dart` (6 cases), `managed_user_model_test.dart` (5 cases). Gates
      green (analyze 0, test 181, parity 378). **Next: FC7 (FILE_07) — shop management.**
- [ ] **FC12–FC15 — Platform ops.** Settings/flags/maintenance+version gates · notification
      center (topics) · media library (R2) · impersonation + dev tools. (FILE_12–15)
- [ ] **FC16–FC18 — Growth + close.** Promotions (coupons/banners/featured) · global search +
      CSV exports + reports · acceptance + security matrix + regression. (FILE_16–18)

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
