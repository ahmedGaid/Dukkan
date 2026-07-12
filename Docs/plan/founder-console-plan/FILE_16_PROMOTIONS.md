# SESSION 16 — Promotions: coupons, admin banners, featured surfaces
# Files: firestore.rules, lib/domain/promos/** (new), lib/data/promos/** (new),
#        lib/presentation/console/promos/** (new), checkout (coupon field + PlaceOrder),
#        lib/domain/order/entities/order.dart (+couponCode/discountMinor),
#        home carousel + home featured row, lib/core/di/injector.dart,
#        lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `PlaceOrder` use case + `checkout_page.dart` — the M12 derive-subtotal + snapshot
   flow the discount slots into.
2. Open the home promo carousel (P1/C2a) — data source and card widget.
3. Open `firestore.rules` `/orders` create rule + the rating-bump pattern in `/shops`
   (`isValidRatingBump`) — the coupon `usedCount` bump copies its shape.
4. Confirm `'banners'` is in the Worker's `ALLOWED_FOLDERS` (done in Session 14).

Do not write anything yet.

---

## Task A — Coupons

`/coupons/{CODE}` (doc id = uppercase code):
`{type: 'percent'|'fixed', valueBps?, valueMinor?, minOrderMinor, expiresAt, maxUses,
usedCount, isActive, createdAt}`.

Rules:

```
    match /coupons/{code} {
      allow read: if isSignedIn();          // checkout validates client-side
      allow create, update, delete: if hasPerm('promos.edit');
      // Redemption bump: any signed-in user, usedCount only, exactly +1 —
      // same shape as the shop rating bump.
      allow update: if isSignedIn()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['usedCount'])
        && request.resource.data.usedCount == resource.data.usedCount + 1;
    }
```

(Note: two `allow update` lines OR-combine in rules — keep them as one expression with
`||` if the linter prefers.)

Checkout: coupon field (apply button → get doc by uppercase id; validate isActive, not
expired, subtotal ≥ minOrderMinor, usedCount < maxUses; designed error copy per failure).
`PlaceOrder`: new optional coupon param — computes `discountMinor`
(percent: `(subtotal * valueBps + 5000) ~/ 10000`, round-half-up like commission; fixed:
`min(valueMinor, subtotal)`), snapshots `couponCode` + `discountMinor` on the order,
`totalMinor = subtotal + deliveryFee - discount`, bumps `usedCount` (+1 write after order
create; failure swallowed — order stands, note the tolerance). Commission stays computed
on the PRE-discount subtotal (platform earns on goods value — locked; comment it).

**Honesty note (code comment + plan):** discount is client-computed under rules-only
validation — bounded (coupon doc read is enforceable, amounts capped by subtotal) but not
Worker-verified. COD marketplace, low fraud surface; hardening path = a Worker checkout
endpoint later. Audit `coupon.create/update/delete` via reportAudit.

## Task B — Banners

`/banners/{id}`: `{imageUrl, targetType: 'shop'|'product'|'none', targetId?, sort,
isActive, startsAt?, endsAt?}`. Rules: read signed-in, write `hasPerm('promos.edit')`.

Home carousel: prepend active banners (sorted, within date window when set) BEFORE the
existing promo-product cards; banner tap → shop page / product detail / nothing. Keep the
existing promo cards behind them (additive — carousel just gets richer).

## Task C — Featured surfaces

- Home: «دكاكين مميزة» row (shops `isFeatured == true`, existing shop card widget) above
  the nearby list — only renders when non-empty (no empty state needed on home).
- Carousel tail: featured products (`isFeatured` from Session 8) after banners + promos,
  capped to keep the carousel ≤ 10 items.

## Task D — Console promos page

`/console/promos` (section perm promos.edit), tabs:
- **الكوبونات**: list (code, type/value, usage x/max, expiry, active chip) + create/edit
  sheet (code uppercase-forced, type toggle, value field switching %↔EGP entry, min order,
  expiry date picker, max uses) + deactivate/delete.
- **البانرات**: list with thumbnails + sort up/down + active toggle; create sheet
  (image upload → `/upload?folder=banners`, target picker: none / shop search / product
  search, optional date window).
- Featured management happens on the shop/product boards (Sessions 7/8) — this tab links
  there («إدارة المميز من لوحة الدكاكين/المنتجات»).
- Audit actions appended: `coupon.*`, `banner.*`.
- Flash sales / seasonal campaigns / popups / referrals: NOT built (locked deferral —
  banners + coupons + featured cover v1 marketing).

i18n both ARBs. Lexicon rows: Coupon → كوبون · Banner → بانر (confirm with BRAND.md
voice — if a better Arabic term exists there, use it).

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Unit tests: percent discount round-half-up cases; fixed > subtotal clamps; expired/
      maxed/min-order validations.
- [ ] Checkout with a real coupon: totals line shows discount, order doc snapshots
      couponCode/discountMinor, usedCount +1; second use past maxUses → designed error.
- [ ] Owner order detail + finance numbers still coherent (commission on pre-discount
      subtotal — verify one order by hand).
- [ ] Banner with shop target shows first in carousel and navigates; deactivating hides
      it without app update.
- [ ] Featured shop appears in the home row; unfeaturing removes it.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_17_SEARCH_REPORTS_EXPORT.md
User action: deploy rules.
```
