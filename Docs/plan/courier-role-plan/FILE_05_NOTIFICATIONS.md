# SESSION 5 — Courier Notifications + Polish + E2E Coverage
# Files: the P2b FCM notify call sites (client), worker/ (only if /notify needs a payload tweak),
#        Docs/testing/E2E_MASTER_PROMPT.md, Docs/Brand/BRAND.md (lexicon),
#        lib/l10n/app_ar.arb + app_en.arb, minor UI touch-ups from the audit

---

## Before You Start

1. Recall `dukkan-brand`.
2. Read how P2b sends pushes today: search `lib/` for the `/notify` call (order status → customer,
   new order → owner). Note: where the FCM token is stored (`/users/{uid}` doc?), who triggers the
   send (client-side after a write?), and the payload shape the Worker expects.
3. Open `worker/` → read the `/notify` handler only far enough to confirm it takes an arbitrary
   target token + title/body (it should — if it hardcodes audiences, note the minimal extension).
4. Open `Docs/testing/E2E_MASTER_PROMPT.md` → find where journeys are listed and how a journey is
   specified (the file is self-maintaining; follow its own format).
5. Open `Docs/Brand/BRAND.md` → find the Arabic lexicon section.

Do not write anything yet.

---

## Task A — Assignment push → courier

Following the exact P2b pattern (same trigger point style, same Worker call):

- When the owner assigns a courier (session 3's `AssignCourier` success path), send a push to the
  courier's FCM token: title `l10n.pushNewDeliveryTitle` ("توصيلة جديدة"), body = shop name +
  short address line.
- Courier devices must register their FCM token the same way customer/owner do — verify the token
  save path is role-agnostic (it should write on any login); fix if it is gated by role.
- Tapping the notification should open the app; deep-link to `/courier/order/:id` ONLY if P2b
  already built tap-routing — otherwise plain open, same as existing pushes. Do not build a new
  deep-link system in this session.

Worker: only touch if `/notify` cannot express this payload; keep any change additive.
(Reminder: the Worker deploy + `FIREBASE_SERVICE_ACCOUNT` secret is a user-side blocker — pushes
can only be live-verified after the user deploys; code + a stubbed/dry-run test are this
session's bar if the Worker isn't deployed yet.)

## Task B — Status push wording check

P2b sends the customer a push on status changes. Verify courier-driven changes
(`outForDelivery`, `delivered`) reuse the SAME notification copy as owner-driven ones — the
customer should never see who pressed the button. No new strings expected; fix only if the copy
was owner-worded.

## Task C — Brand + polish audit (courier surfaces)

Run the `dukkan-brand` checklist over every screen this plan added (signup third card, join page,
owner couriers page, assign sheet, courier shell, delivery detail):

- One Arabic word per concept: مندوب التوصيل everywhere (grep the arb for "ديليفري"/"طيار" — must be zero).
- Dark mode pass on all new screens on device.
- RTL: numbers, phone rows, steppers read correctly; no physical left/right paddings.
- Every empty/error/loading state designed — none bare.
- Add **مندوب التوصيل — courier** to the BRAND.md lexicon with the one-line usage rule.

Fix what the audit finds (small diffs only; anything structural goes back to its session file).

## Task D — E2E master prompt

Append a courier journey to `Docs/testing/E2E_MASTER_PROMPT.md`, following the file's own journey
format, covering at minimum: courier signup → join shop by code → owner assigns →
courier advances both legs → customer sees delivered + rates → owner removes courier →
removed courier gets no new assignments offered. Also add the two negative checks
(foreign courier can't read others' orders; customer can't join as courier).

---

## Smoke Test

- [ ] Gates green (analyze / test / parity).
- [ ] Assign an order on device → courier device (or same device, courier account with token) receives "توصيلة جديدة" push — or, if Worker undeployed, the notify call is logged/stubbed correctly.
- [ ] Customer status pushes unchanged in wording for courier-driven advances.
- [ ] grep arb files: zero hits for "ديليفري" / "طيار"; BRAND.md lexicon updated.
- [ ] Dark mode + RTL spot-check on all new screens: clean.
- [ ] E2E prompt contains the courier journey and reads consistently with existing journeys.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, mark D5, commit + push
→ Clear session, then open FILE_06_ACCEPTANCE.md and finish
```
