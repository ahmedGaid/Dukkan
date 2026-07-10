# Dukkan — Play Store listing copy (R1)

Arabic is the primary listing (Egypt / `ar`); English (`en-US`) is the parity fallback.
Character limits are Google Play's. Keep the shopkeeper voice: friendly, warm, direct,
never salesy. Lexicon is law (`Docs/Brand/BRAND.md` §6): دكان · طلب · السلة ·
الدفع عند الاستلام · صاحب الدكان.

> **Screenshots + feature graphic are still pending** — they need the app running on a
> device with seeded data (blocked on the Firestore `(default)` DB). Capture list is at the
> bottom so they can be shot in one pass once the app runs.

---

## Arabic (ar) — primary

**App title** (≤ 30 chars)
```
دكان — دكاكين حيّك
```

**Short description** (≤ 80 chars)
```
اطلب البقالة من دكاكين حيّك، والدفع عند الاستلام. بسيط وسريع.
```

**Full description** (≤ 4000 chars)
```
دكان بيقرّب دكاكين حيّك من إيدك.

اتفرّج على الدكاكين القريبة منك، اطلب البقالة اللي محتاجها، وادفع عند الاستلام —
من غير تعقيد ومن غير رسوم مستخبّية.

الطلب في خطوات بسيطة:
• دوّر على دكان قريب منك أو ابحث عن المنتج اللي عايزه.
• زوّد اللي محتاجه في السلة من صفحة الدكان.
• أكّد عنوانك، وابعت الطلب — والدفع عند الاستلام.
• تابع طلبك لحظة بلحظة: بانتظار التأكيد، بيتجهّز، في الطريق إليك، لحد ما يوصل.

ليه دكان؟
• دكاكين حيّك في مكان واحد — مش لازم تدوّر في كذا تطبيق.
• أسعار واضحة، وكل حاجة بالعربي.
• الدفع عند الاستلام — تدفع لما الطلب يوصلك.
• تتبع مباشر لحالة الطلب، وإشعار أول ما تتغيّر.
• قايمة مفضّلاتك — رجّع لأكتر دكان وأكتر منتج بتطلبه بضغطة.

عندك دكان؟ اعرض بضاعتك أونلاين:
• اعمل صفحة لدكانك في دقايق — الاسم، العنوان، وصورة.
• زوّد منتجاتك وأسعارها، وافتح واقفل الدكان وقت ما تحب.
• استقبل الطلبات وأنت في محلك، واقبلها أو ارفضها بضغطة.
• حرّك حالة الطلب خطوة خطوة لحد ما يوصل للزبون.

دكان — دكانك القريب، في جيبك.
```

**Notes to store**
- Category: Shopping · Content rating: Everyone · Contains ads: No · In-app purchases: No
  (v1 is cash on delivery only).
- Default language: Arabic (Egypt). English added as a second listing.

---

## English (en-US) — parity

**App title** (≤ 30 chars)
```
Dukkan — Neighborhood Shops
```

**Short description** (≤ 80 chars)
```
Order groceries from shops near you. Cash on delivery. Simple and fast.
```

**Full description** (≤ 4000 chars)
```
Dukkan brings your neighborhood shops to your pocket.

Browse the shops near you, order the groceries you need, and pay when they arrive —
no fuss, no hidden fees.

Ordering takes a few simple steps:
• Find a shop near you, or search for the product you want.
• Add what you need to your cart from the shop's page.
• Confirm your address and place the order — pay cash on delivery.
• Follow your order in real time: pending, being prepared, on its way, delivered.

Why Dukkan?
• All your neighborhood shops in one place — no juggling apps.
• Clear prices, fully in Arabic and English.
• Cash on delivery — pay only when your order reaches you.
• Live order tracking with a notification on every status change.
• Favorites — one tap to reorder from the shops and products you love.

Own a shop? Put it online:
• Set up your shop page in minutes — name, address, and a photo.
• Add your products and prices; open or close the shop whenever you like.
• Take orders from behind your counter, and accept or reject with one tap.
• Move each order forward, step by step, until it reaches the customer.

Dukkan — your corner shop, in your pocket.
```

---

## Screenshot capture list (shoot once the app runs — phone, 1080×1920+)

Customer flow (light mode; shoot 2–3 in dark too):
1. Home — promo carousel + category grid + nearby shops.
2. Shop page — header (open) + product grid.
3. Product detail — inline add-to-cart.
4. Cart + checkout — items + cash-on-delivery confirm.
5. Order tracking — status stepper ("في الطريق إليك").

Shop-owner flow:
6. Order desk — incoming orders (realtime) with accept/reject.
7. Catalog manager — product list with stock/promo toggles.

Feature graphic (1024×500): mark + wordmark on a deep-green (#12362A) field,
tagline "دكانك القريب، في جيبك".
