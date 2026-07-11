# SESSION 2 — Owner Order Details Page
# Files: lib/presentation/orders/pages/order_detail_page.dart (or a new owner variant — decide after reading), order_desk_page.dart, app_ar.arb, app_en.arb

---

## Before You Start

1. Open `lib/presentation/orders/pages/order_detail_page.dart` — this is the CUSTOMER detail page. List which spec fields it already shows: order id, created-at, status, address, notes, items (image/name/qty/unit/total), total.
2. Open `order_desk_page.dart` — find how the owner opens an order today (inline expand? navigates to detail page?).
3. Check router (`lib/core/router/`) for the order-detail route and what role reaches it.
4. Check `app_ar.arb` for existing order keys (search `order`) — reuse, don't duplicate.

Do not write anything yet.

---

## Task A — One detail page, role-aware

Reuse `order_detail_page.dart` for both roles rather than forking. Owner-only additions gated on role (the page can receive an `isOwner` flag from the route, or read the auth bloc — match how other pages branch on role):

- **Customer block** (owner view only): customer name + phone from the order's stored contact info. If the order doc does not store name/phone today (check Task 1 reading — the seed orders may only have `customerUid`), fetch the `/users/{customerUid}` doc via the existing user repository. Phone row is tappable → `tel:` launch, same pattern as any existing call button (search the codebase for `url_launcher` usage; if none exists, show phone as selectable text — do NOT add a dependency without asking).
- **Payment method row**: static — COD only. Keys `orderPaymentMethod` / value key `paymentCod` → ar: `الدفع عند الاستلام`, en: `Cash on delivery`.
- **Fee/total block**: subtotal, delivery fee, total — all via `core/money.dart` formatting. Until Session 12 adds real fee fields, show subtotal = `totalMinor`, delivery fee = 0.
- **Driver block placeholder**: render only when order has `driverUid` (Session 9 adds it) — build the widget now behind a null check so Session 9 only wires data.

## Task B — Timeline widget

Add a `_OrderTimeline` widget at the bottom of the detail page consuming `order.statusHistory`:

- Vertical list, oldest first: status chip (reuse the existing status chip widget from `presentation/widgets/common/`) + localized relative/absolute time.
- Empty history (old seeded orders): render single row from `order.status` + `order.createdAt` — never a blank section (designed-states rule).
- All status names come from existing status i18n keys — do not invent new Arabic words.

## Task C — Owner desk → details navigation

From `order_desk_page.dart`, ensure each order card navigates to the detail page with the owner flag. Keep existing quick status actions on the desk card working unchanged.

## Task D — Access control check

Rules already scope orders by `shopId`/`customerUid` — verify the detail page only ever receives orders from the lists the role can query. No new rules needed; confirm by reading the two queries.

---

## Smoke Test

- [ ] Owner (seed-owner@dukkan.dev) opens any of the 7 seeded orders from the desk → sees id, date, status, customer name+phone, address, payment (COD), items with images/qty/prices, total, notes.
- [ ] Timeline renders; old seeded orders show the single-row fallback, new orders show full history.
- [ ] Customer view unchanged: no customer block, no owner actions.
- [ ] RTL: all rows read correctly in Arabic; money formatted via money.dart (ج.م + Arabic numerals).
- [ ] Gates green (`analyze`, `test`, i18n parity).

---

## After This Session

```
Smoke test passed?
→ update dukkan-status → commit
→ /compact → open FILE_03_TAXONOMY_DATA.md
```
