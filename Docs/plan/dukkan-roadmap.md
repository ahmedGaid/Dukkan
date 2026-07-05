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
/users/{uid}       role: 'customer'|'owner', name, phone, address?
/shops/{shopId}    ownerUid, name, nameAr, logoUrl, address, isOpen, categories[]
/products/{id}     shopId, name, nameAr, imageUrl, priceMinor (int, piasters),
                   category, stockStatus, isPromo
/orders/{id}       shopId, customerUid, items[], totalMinor, status, createdAt,
                   deliveryAddress, notes?
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
- [ ] **S1 — Shop onboarding.** Owner signup flow → create shop profile (name ar/en, logo upload
      to Storage, address, open/closed toggle).
- [ ] **S2 — Catalog manager.** Product CRUD, image upload, price (piasters!), stock toggle,
      promo flag.
- [ ] **S3 — Order desk.** Incoming orders list (realtime), accept/reject, advance status,
      daily summary strip.

### Phase 3 — Polish
- [ ] **P1 — Favorites + promos + states pass.** Favorite shops/products, promo carousel wired to
      real promo flags, full empty/error-state audit.
- [ ] **P2 — Notifications + settings.** FCM push (order status → customer, new order → owner),
      settings page, dark-mode audit against `logo-dark.png` palette.
- [ ] **P3 — Ratings.** Shop rating after delivered order, average on shop card.

### Phase 4 — Release
- [ ] **R1 — Store prep.** Adaptive icon + splash from logo, Arabic store listing copy,
      screenshots.
- [ ] **R2 — Ship.** Crashlytics, release build signing, Play internal testing track.

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
