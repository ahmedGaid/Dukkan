# Dukkan — Brand

Logo files: `assets/brand/logo-light.png` (light bg) · `assets/brand/logo-dark.png` (dark bg).
Mark: rounded **D** monogram with a shop **awning** (دكان = the neighborhood shop).

## Personality

**Your neighborhood shop, in your pocket.** Friendly, warm, trustworthy, simple.
Not corporate, not loud. Speaks Egyptian Arabic like a good shopkeeper: welcoming, direct,
never salesy. (Contrast with Conductor ERP which is quiet/precise — Dukkan is warmer.)

**Bar: premium, minimal, not generic.** Warm ≠ cheap, minimal ≠ empty. Every screen should
feel crafted enough to become THE recognizable brand in Arabic grocery-delivery — not a
template clone. Cut before you add: every element on screen must earn its place. Prefer the
more distinctive/polished/simpler option whenever craft and "just functional" disagree.

## Color (from logo — the only place raw hex is allowed is `AppColors` in Flutter)

```dart
// Brand
primary       = Color(0xFF12362A)   // deep green — text-strong, CTAs on light, chrome
primaryBright = Color(0xFF4DBB87)   // mint/awning green — accents, active states, dark-mode primary
awning        = Color(0xFF57C793)   // lighter mint — highlights, promo chips

// Semantic
success = Color(0xFF2E9E6B)   // stays in the green family
warning = Color(0xFFE8A13D)
error   = Color(0xFFD9534F)
info    = Color(0xFF3D7FA6)

// Light surfaces
surface        = Color(0xFFFFFFFF)
surfaceVariant = Color(0xFFF4F7F5)  // scaffold — green-tinted near-white
outline        = Color(0xFFE2EAE5)

// Dark surfaces (from logo-dark)
darkBg      = Color(0xFF0A0F0D)
darkSurface = Color(0xFF121A16)
darkCard    = Color(0xFF18231D)
```

Rules:
- Green is THE brand. No second brand color. Semantic colors only inside content
  (status chips, deltas), never in the app chrome.
- Color always pairs with a word or icon — never color alone carries meaning.
- Dark mode: mint (`primaryBright`) becomes the primary; deep green recedes.

## Type

- Arabic: **IBM Plex Sans Arabic** (same family the founder already uses — one voice across products).
- Latin: **Inter**.
- Rounded, friendly weights: titles 600, body 400. No third font ever.

## Spacing / radius (rounded like the logo)

```dart
// Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
// Radius:  sm=10, md=14, lg=18, xl=24, round=100   ← slightly rounder than default; logo is round
```

## Voice & Arabic lexicon (one canonical word per concept — add here BEFORE shipping)

| Concept | Arabic | Never |
|---|---|---|
| Shop | دكان (pl. دكاكين) | متجر، محل |
| Order | طلب | أوردر |
| Cart | السلة | عربة التسوق |
| Checkout | إتمام الطلب | الدفع |
| Cash on delivery | الدفع عند الاستلام | كاش |
| Out for delivery | في الطريق إليك | قيد الشحن |
| Shop owner | صاحب الدكان | التاجر، البائع |
| Order status: pending | بانتظار التأكيد | قيد المراجعة |
| Order status: accepted | مقبول | تم الموافقة |
| Order status: preparing | بيتجهّز | قيد التحضير |
| Order status: delivered | اتوصّل | تم التسليم |
| Order status: cancelled | ملغي | اتلغى |
| Order status: rejected | مرفوض | اترفض |
| Owner accepts order | قبول | الموافقة |
| Owner rejects order | رفض | الرفض |
| Owner catalog tab | الكتالوج | المنتجات |
| Order history/timeline | سجل الطلب | تايم لاين |
| Driver (delivery) | المندوب | السائق |
| Category | القسم | الفئة، التصنيف |
| Subcategory | القسم الفرعي | الفئة الفرعية |
| Collection (owner-curated grouping) | مجموعة | فئة، تصنيف |
| Courier picked up the order | استلمت الطلب | استلام الشحنة |
| Courier delivered the order | تم التوصيل | تم الشحن |
| Courier online/offline switch | أونلاين / أوفلاين | متاح / غير متاح |
| Finance (founder-only summary) | المالية | الحسابات، التقارير المالية |
| Permission (staff capability) | صلاحية | إذن، تصريح |
| Activity / audit log (console) | سجل العمليات | سجل التدقيق، اللوج |
| Console (founder back office) | لوحة التحكم | لوحة الإدارة، الأدمن |
| Founder (top staff role) | المؤسس | الأدمن، المالك |

- Human statuses ("جارٍ تجهيز طلبك"), blame-free errors ("حصلت مشكلة — جرّب تاني").
- RTL is the default layout. LTR (English) must read identically well.

## Image / illustration style (product art, empty states, promos, stickers)

Reference feel: flat "sticker" cartoon of a product (e.g. the Skittles pack sample in
`Docs/ui-ref/` if saved) — playful, hand-drawn-adjacent, instantly readable.

Rules — every illustrated image Dukkan ships follows ALL of these:
1. **White background. Always.** Pure `#FFFFFF`, no scene, no floor shadow, no gradient
   backdrop. Subject floats clean on white (works on cards, lists, and both themes).
2. **Bold uniform outline.** Single dark stroke (near-black), one consistent weight around
   every shape. No sketchy/variable linework.
3. **Flat fills, no rendering.** Saturated flat colors; at most one simple flat highlight
   shape. No gradients, no 3D, no photorealism, no soft shadows inside the art.
4. **Real product colors allowed** inside the artwork (a red pack stays red) — brand green
   stays the accent around it (chips, badges, buttons), never forced onto the product.
5. **Playful tilt.** Single subject, centered, rotated ~5–12° for energy. One subject per
   image — no clutter, no busy compositions.
6. **Rounded forms** — corners and shapes echo the logo's roundness; nothing sharp/spiky.
7. Same style for ALL illustration surfaces: product placeholders, category art, empty
   states, promo banners, onboarding. One hand, one style — never mix with stock photos,
   3D renders, or a second illustration style.

## UI/UX reference — Ben Soliman (com.BenSoliman.BSS)

Patterns to borrow (screenshots live in `Docs/ui-ref/` when provided):
promo carousel on home, category grid, big product cards with inline +/− add,
order-tracking stepper, bottom nav (Home / Orders / Cart / Profile).
Borrow *patterns*, never their visual identity — Dukkan looks like Dukkan.

## Every screen must have

Designed empty state (warm illustration/emoji + one action), designed error state,
shimmer/skeleton loading. Never bare "No data" / blank / raw exception.
