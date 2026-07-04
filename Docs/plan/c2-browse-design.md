# C2 — Browse: design direction

> Read before building any C2 screen. Pairs with the `dukkan-brand` skill + `BRAND.md` tokens.
> Reference screenshots (Ben Soliman, "BSS") in `Docs/ui-ref/` — **borrow patterns, never their
> visual identity.**

## The one structural rule
Ben Soliman is a **single wholesale store**. Dukkan is a **consumer marketplace** — many دكاكين.
So the Dukkan home leads with **shops + categories**, and products live *inside* a shop. Do NOT
copy BSS's products-on-home layout.

Flow: Home (pick a دكان or category) → Shop page (that shop's products) → Product detail → add to
السلة. One cart per shop (roadmap locked decision).

## Borrow / Kill / Improve (from the BSS screenshots)

**Borrow (patterns only):**
- Home rhythm: search → promo carousel → shortcut chips → sectioned rails.
- Category grid (3-col). Product card with inline **add → stepper** morph. Floating cart summary.
- Bottom nav (4–5 destinations).

**Kill (their identity — off-brand for us):**
- Red "عرض عشانك" ribbons, red trash buttons, orange + buttons — 3–4 loud colors fighting. Dukkan
  is quiet/warm.
- Heavy borders + drop shadow on every card; inconsistent radii.
- Half-empty category tiles (look broken/unfinished).
- "رابطة = 20 كيس" wholesale unit chips — B2B-only, not consumer.

**Improve to Linear-craft + shopkeeper-warm:**
- **One green brand only** (`AppColors.primary` deep + `primaryBright`/`awning` mint). Promo = quiet
  mint tag reading `عرض`, never red. Semantic color only inside content, always with a word/icon.
- **One soft shadow** (define once, reuse), radius strictly sm10/md14/lg18/xl24, no magic numbers.
- Generous whitespace; let items breathe (minimal = cut, not shrink).
- Strong type hierarchy straight from `AppTypography` (titleLarge 22/600 → bodySmall 12/400).
- Every empty/loading/error **designed** (warm illustration/glyph + one action). Settled motion only.
- Bar: "would this stand out on the Play Store, and would a دكان owner in Shubra brag about it?"

## Screens (build order = session order)

### C2a — UI foundation + Home
Reusable widgets in `presentation/widgets/common/` (build once, never fork):
- `AppCard` (surface, radius md/lg, one soft shadow, no border by default).
- `PriceTag` (consumes integer piasters → `Money.format`; deep-green amount).
- `ShimmerImage` (network image w/ shimmer placeholder + designed fallback glyph).
- `EmptyState` (warm glyph + title + optional action) — used by every list.
- `GridShimmer` / list shimmer (loading skeletons, not a spinner page).
- `StatusChip` (open/closed shop, stock — human words, semantic-with-word).
- Bottom-nav shell (`HomeShell` with IndexedStack): الرئيسية / الاقسام / المفضلة / الطلبات / المزيد
  (favorites+orders are placeholders until C4/P1 — designed "coming soon", never blank).

Home screen sections (RTL, logical CSS):
1. Header: logo (near-black/mint, monochrome) + search entry (routes to C2c search).
2. Promo carousel — calm mint banners, dot indicator, reduced-motion aware.
3. Category grid (3-col) — from shop `categories`; tapping filters shops/products (wire in C2b).
4. Nearby shops list — shop cards (logo, nameAr, open/closed StatusChip, address line).
5. States: loading = shimmer, empty = "مافيش دكاكين قريبة لسه" + retry, error = blame-free + retry.
`ShopsBloc` drives it (WatchShops use case; buildWhen; BlocListener for errors).

### C2b — Shop + products
- Shop page: header (logo, name, open/closed, address), in-shop category filter row, product grid.
- Product grid: `ProductCard` (image, nameAr, PriceTag, add→stepper, promo mint tag, stock state).
- Product detail: large image, name, price, stock, quantity + add-to-cart (cart wiring lands C3).
- `ProductsBloc` (WatchProductsByShop). Out-of-stock = disabled add + human label, not hidden.

### C2c — Search + polish
- Product search (across a shop, or global — decide at build). Debounced, designed empty/no-results.
- Cross-screen pass: verify every empty/loading/error is designed and on-brand; motion settled.

## New Arabic lexicon needed (add to BRAND.md §lexicon BEFORE shipping the string)
Confirm/instantiate canonical words: دكان/دكاكين (shop/shops), الأقسام (categories), عروض (offers),
السلة (cart), المفضلة (favorites), متاح/مقفول (open/closed), خلص من المخزن (out of stock),
أضف للسلة (add to cart). One word per concept — check the table, don't invent a second.

## i18n + gates
Every string = key in both ARB (parity build-blocking). Run before "done":
`flutter analyze` · `flutter test` · `dart run scripts/check_i18n_parity.dart` · `dukkan-brand`
brand-feel checklist (UI work). No live browser run yet (no device wired) unless a target is set up.
