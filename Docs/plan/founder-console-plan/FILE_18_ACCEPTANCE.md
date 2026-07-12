# SESSION 18 — Acceptance: security verification, regression, sign-off
# Files: none new (fixes only) · Docs/testing/E2E_MASTER_PROMPT.md ·
#        Docs/plan/dukkan-roadmap.md · dukkan-status skill

---

## Before You Start

1. Confirm ALL rules blocks and indexes from sessions 1–16 are DEPLOYED and the Worker is
   at the latest deploy — this session tests the LIVE stack, not the repo.
2. Have four test accounts ready: founder, a support-role staff (seed via
   `/admin/admins/set`), a customer, an owner. Device `R5CNC0NK6ZT` + one desktop target
   (`flutter run -d windows` or web).
3. Load `Docs/testing/E2E_MASTER_PROMPT.md` — you will append console journeys at the end.

Do not write anything yet.

---

## Task A — Functional acceptance (founder, desktop first, then phone)

- [ ] Dashboard: every tile shows a real number; refresh works; 7-day chart plausible.
- [ ] Users: search → detail → suspend/unsuspend → reset email → persona role change →
      staff role grant/revoke → soft delete/restore. Audit entries for each.
- [ ] Shops: pending → approve; suspend hides from customer home/search; featured/verified
      toggles; ownership transfer; create-shop-for-owner.
- [ ] Products: cross-shop board filters; edit; duplicate; soft delete/restore; bulk price
      +10% on 3 products (hand-verify rounding); bulk category move.
- [ ] Taxonomy: add/hide/reorder category → home grid follows; product form follows.
- [ ] Geo: add area → checkout shows it; fee override lands in a new order snapshot;
      deactivate hides it.
- [ ] Orders: board filters; staff detail; force status with reason (timeline shows
      تصحيح إداري); reassign driver (counts move); internal note (invisible to
      customer/owner/courier).
- [ ] Drivers: activate the suspended seed driver → assignable; suspend → courier banner.
- [ ] Settings: commission edit reflected in NEXT order only; maintenance mode blocks
      customer, passes founder; min build gate; feature flag toggle readable via helper.
- [ ] Notifications: broadcast to customers arrives (only them); direct send; template;
      history + failed resend.
- [ ] Media: browse; stats; orphan finder truthful; bulk delete.
- [ ] Impersonation: enter (banner everywhere) → act → exit → founder restored; both audit
      entries; kill-app-mid-session recovery.
- [ ] Devtools: health checks green; test notification; fake orders generate + cleanup;
      migration idempotent.
- [ ] Promos: coupon full lifecycle at checkout (+usedCount, discount math); banner in
      carousel; featured shop row.
- [ ] Search/exports/reports: Ctrl+K each entity type; CSV opens in Excel (Arabic OK);
      reports totals cross-check dashboard.
- [ ] All of the above spot-checked on PHONE width (drawer nav) + dark mode + English.

## Task B — Security verification matrix (the point of the whole plan)

As CUSTOMER account:
- [ ] `/console` deep link bounces to `/home`; Settings shows no console row.
- [ ] Direct Firestore writes (debug script or temporary button) to `/admins`, `/roles`,
      `/auditLogs`, `/config`, `/categories`, `/areas`, `/coupons`, another user's
      `/users` doc → ALL denied.
- [ ] Worker: `/admin/ping`, `/admin/users/set-disabled`, `/admin/impersonate` with the
      customer's ID token → 403; no token → 401.
- [ ] Cross-user reads: another customer's order → denied; `/auditLogs` read → denied.

As SUPPORT-role staff (users.read + orders.read + orders.update only):
- [ ] Console shows ONLY dashboard/users/orders/audit-less sections per its perms; hidden
      sections' routes bounce; Firestore writes to products/config denied; Worker
      `admins/set` → 403; impersonate → 403.
- [ ] Support CANNOT read `/auditLogs` (no auditlogs.read) — section absent + rules deny.

As ADMIN-role staff:
- [ ] Cannot touch founder: `admins/set` on founder 403, impersonate founder 403.

Founder break-glass: temporarily rename the founder's `/admins` doc id (console) →
`isFounder()` literal still opens finance; restore the doc. (Proves the bootstrap path.)

## Task C — Regression (v1 + Marketplace V2 untouched)

- [ ] Customer: browse → cart → coupon-less checkout → order → realtime status → rate.
- [ ] Owner: order desk accept→deliver self-delivery path; catalog CRUD; collections.
- [ ] Courier: online → assigned → picked up → delivered (+ commission flip, counts).
- [ ] Pushes: newOrder / statusUpdate / driverAssigned / orderDelivered still arrive.
- [ ] Finance page numbers consistent with reports page.
- [ ] `flutter analyze` 0 · `flutter test` green · parity script green — final run.

## Task D — Micro-polish pass

Fix (don't redesign): misaligned tiles, missing empty states on any console list, RTL
chevrons, dark-mode contrast on chips, any bare English string that slipped.

## Task E — Sign-off

- Append console journeys (J15 «إدارة» series) to `Docs/testing/E2E_MASTER_PROMPT.md`
  Phase 2, mirroring how J13/J14 were added.
- Roadmap: mark Phase 7 done; dukkan-status: position + NEXT ACTION (post-console = ship).
- Sign-off block in this file's commit message: what was built (18 sessions), what was
  deliberately NOT built (crop/compress, scheduled sends, flash sales, referrals,
  retention, Excel/PDF, bulk import, country tables), what stays external (rules/index
  deploys, Crashlytics, Play Console, wrangler).

---

## After This Session

```
GREEN?
→ Founder Console is the operating system of the business.
→ Update dukkan-status, commit, push, fresh session.
→ Daily E2E (standing regression) now includes J15.
```
