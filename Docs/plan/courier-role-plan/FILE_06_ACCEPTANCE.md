# SESSION 6 — Acceptance + Regression + Sign-off

# Files: none new — this session verifies, fixes small gaps, and signs off.

---

## Before You Start

1. Recall `dukkan-brand` + `dukkan-flutter`.
2. Read `FILE_00_INDEX.md` end to end.
3. Confirm sessions 1–5 are all marked done in the roadmap (Phase 5, D1–D5).
4. Have three accounts ready on device `R5CNC0NK6ZT`: one customer, one owner (with shop + seeded
   products), one courier. Firestore rules deployed at their latest version.

---

## Full acceptance checklist

**Signup + identity**
- [ ] Signup offers exactly three role cards; courier card labeled "مندوب توصيل" (ar) / "Courier" (en).
- [ ] Courier account: `/users/{uid}` doc has `role: 'courier'`; settings shows "مندوب التوصيل".
- [ ] Role is fixed after signup (rules reject a role change — verify in rules playground).

**Membership**
- [ ] Owner couriers page shows invite code + copy; sharing code lets courier join; owner sees courier in realtime.
- [ ] Wrong code → clear error. Owner remove → courier disappears; removed courier keeps history but is no longer assignable.
- [ ] Customer role cannot join as courier (rules).

**Assignment + delivery**
- [ ] Owner assign row appears only when the shop has ≥1 courier; assignment while accepted/preparing only.
- [ ] Assigned courier sees the order in realtime; advances `preparing → outForDelivery → delivered` (with confirm on delivered).
- [ ] Customer stepper + pushes track courier-driven changes exactly as owner-driven ones.
- [ ] Delivered order: customer can rate (P3 intact); order sits in courier history.
- [ ] A second courier sees none of it; an unassigned order is invisible to all couriers.

**Pushes (if Worker deployed)**
- [ ] Assignment push reaches the courier device.

## Regression checklist (must all still work)

- [ ] Owner with NO couriers: order desk byte-for-byte identical flow — accept/reject, advance all
      statuses himself, including `outForDelivery → delivered`.
- [ ] Customer core: browse, search, cart, checkout (COD), cancel pending/accepted, rate delivered.
- [ ] Existing accounts (created before this plan) log in fine; `fromWire` fallback keeps any
      malformed role as customer.
- [ ] Favorites, promos, settings (language/theme/logout), dark mode — untouched screens unchanged.
- [ ] Gates: `flutter analyze` 0 · `flutter test` all green (old 56 + all new) · i18n parity passes.
- [ ] Run the FULL `Docs/testing/E2E_MASTER_PROMPT.md` including the new courier journey → GREEN
      (or GREEN-WITH-SKIPS with only human-blocked items, e.g. undeployed Worker).

## Micro-polish pass (apply if missing)

- [ ] Copy-invite-code gives haptic/snackbar feedback.
- [ ] Courier list rows show joined-date in the app's existing date format (no new formatter).
- [ ] Delivery detail address block has a copy affordance if C4's detail has one.
- [ ] All new screens honour reduced-motion and text-scale like the rest of the app.

## Sign-off block

When everything above is checked, write into the session report:

- **Built:** courier role (مندوب التوصيل) — third signup role, shop membership by invite code,
  owner assignment, courier delivery shell, delivery-leg permissions, assignment push, E2E journey.
- **Not touched:** money handling, customer purchase flow, owner catalog, deps, Firebase config.
- Update `dukkan-status`: Phase 5 DONE, NEXT ACTION back to the roadmap queue.
- Mark Phase 5 fully `[x]` in `Docs/plan/dukkan-roadmap.md`. Commit + push. Fresh session.
