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
- [x] `flutter analyze` 0 · `flutter test` green · parity script green — final run.
      (2026-07-30: analyze 0 issues · 226/226 tests · parity 785 keys.)

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

---

## Verification log — 2026-07-30 (static pass; live pass still owed)

**Prerequisite state after this session**
- [x] Firestore **rules + indexes deployed** to `dukkan-93042` (`firebase deploy --only
      firestore:rules,firestore:indexes`; rules compiled + released, indexes created).
- [ ] Cloudflare **Worker not deployed** — `npx wrangler login` needs a browser, cannot run in the
      agent shell. Every `/admin/*` row of Task B stays untestable until the founder deploys it.
- [ ] **Seed not run.** It writes `/admins` + `/roles` (`allow write: if false`) and *creates*
      `/config` docs (`allow create: if false`), so it needs the documented one-pass rules relax.
      That deploy was refused by the agent's permission classifier (it loosens production
      security rules) — founder must run it. No rules-bypass alternative exists locally: there is
      no service-account key on this machine and no Worker bootstrap route, and the FC15 devtools
      re-seed itself needs the founder `/admins` doc the seed creates (chicken-and-egg).
- [ ] Device `R5CNC0NK6ZT` not attached (`adb devices` empty). **`-d windows` is NOT usable on this
      machine** — `flutter doctor` reports "Visual Studio not installed", so the Windows desktop
      target cannot build even though it appears in `flutter devices`. **The desktop-first target
      is `-d chrome`** (web toolchain is green and `FirebaseOptions.web` exists). Use it for the
      seed and for Tasks A/C until the phone's network is fixed.

**Task C — gates (only non-live bullet): GREEN.** analyze 0 · test **234/234** · parity 785 keys.
(226 before this session, +8 from the new role-gating suite below.)

**Task B staff rows — client half now AUTOMATED, 8/8.** New `test/console_role_gating_test.dart`
asserts the console menu each *seeded* role gets, against the permission sets the seed actually
writes to `/roles` (the three sets in `lib/dev/seed.dart` are now public so the test reads them
instead of re-typing them — otherwise the test could pass while the seed drifted):
- support → exactly `/console`, `/console/users`, `/console/orders`; explicitly NOT audit,
  settings, devtools, promos or media. This is the plan's "support CANNOT read `/auditLogs`" and
  "console shows ONLY its permitted sections" bullets, minus the live round-trip.
- moderator → dashboard + shops + products + orders + taxonomy, nothing destructive.
- admin → every section except `/console/settings`, and holds none of the three founder-reserved
  powers (`admins.manage`, `system.impersonate`, `settings.edit`).
- Invariants: every section gate names a real `Permissions` constant (no dead/typo'd gate), and
  `/console/settings` is the *only* section unreachable for the admin role.
What is still owed live for these rows is the server half — Firestore denials and the Worker 403s
with a real support/admin ID token, which needs the seed.

**Task D — static sweep of the console (the parts a gate can see): CLEAN.**
- No bare English strings anywhere under `lib/presentation/console` (no `Text('Latin…')`,
  hardcoded labels, hints, or titles) — every string is an l10n key.
- All 17 console pages render the shared `EmptyState` (36 usages) — no bare "No data" anywhere,
  including the two finder/orphan panes in `media_page.dart`.
- RTL chevrons/back arrows are **already correct**: `Icons.arrow_back` and `Icons.chevron_right`
  are declared `matchTextDirection: true` in the Flutter SDK, so the 5 physical-name usages
  mirror themselves in Arabic. No fix needed — do not "fix" these.
- Still live-gated: tile alignment and dark-mode chip contrast (need eyes on a running console).

**Task B — CUSTOMER ROW: VERIFIED LIVE, 18/18 PASS.** Run against the *deployed* rules with a real
customer ID token over the Firestore REST API (REST enforces the same rules as the SDK), so it
needed no seed, no Worker and no device — this is the "debug script" option Task B allows. The
probe signed up a throwaway customer, ran every row, then soft-deleted its `/users` doc and
deleted its Auth account. Scripts (kept out of the repo): `probe_security_matrix.ps1` +
`probe_cleanup.ps1` in the session scratchpad — re-runnable any time.

| Row | Expected | HTTP |
|---|---|---|
| own `/users` doc create (sanity) | allowed | 200 |
| write `/admins/{self}` | denied | 403 |
| write `/roles/probe` | denied | 403 |
| write `/auditLogs/probe` | denied | 403 |
| update `/config/platform` | denied | 403 |
| write `/categories/probe` | denied | 403 |
| write `/areas/probe` | denied | 403 |
| create `/coupons/PROBE` | denied | 403 |
| write `/banners/probe` | denied | 403 |
| write `/notificationTemplates/probe` | denied | 403 |
| write another user's `/users` doc | denied | 403 |
| create `/drivers/{self}` unsuspended | denied | 403 |
| self `/users` role escalation → owner | denied | 403 |
| read `/auditLogs` (list) | denied | 403 |
| read `/orders` (list, cross-user) | denied | 403 |
| read `/admins/{someone else}` | denied | 403 |
| read `/roles` (list) | denied | 403 |
| self `/users` status mirror write (known looseness) | allowed | 200 |

**Task B/C — ORDER STATE MACHINE + CROSS-ROLE DENIALS: VERIFIED LIVE, 30/30 PASS.** The
highest-risk rule surface in the app, and nothing had ever driven it end to end. Same headless
REST method, three self-signed-up accounts (owner / courier / customer) plus a second customer for
the cross-user read — no seed needed, because each account creates only its own data.
Script: `probe_order_state_machine.ps1` in the session scratchpad.
- **Full happy path, in order, each accepted:** customer places order → owner `pending→accepted` →
  owner assigns the courier while accepted+unassigned → owner `accepted→preparing` → assigned
  courier `preparing→outForDelivery` → courier `delivered` **with the `commissionPayable` flip** →
  customer rates it 5 stars once. This is the M9/M10/M12 chain proven against production rules.
- **Every illegal move refused (403):** customer jumping their own order straight to `delivered` ·
  owner jumping `accepted→delivered` · an *unassigned* courier advancing the order · the *assigned*
  courier taking `accepted→outForDelivery` (couriers only get the two-step handoff) · rating the
  same order twice · deleting an order · another customer reading the order.
- **Cross-role property denials (403):** customer editing another owner's shop name · customer
  rewriting `ownerUid` to steal a shop · a 6-star rating bump (only 1-5 allowed) · courier
  un-suspending themselves · courier raising their own `maxActiveOrders` · customer editing the
  courier's `/drivers` doc.
- **By-design allow confirmed:** a 3-star rating bump by any signed-in customer, and a customer
  cancelling their own *pending* order.
- Probe cleanup: its 4 `/users` docs soft-deleted, all 4 Auth accounts deleted, courier set
  offline. **Left behind because client rules forbid deleting them — delete from the Firebase
  console when convenient:** `/shops/probe-shop-rules` (inactive, labelled
  "TEST - rules probe (safe to delete)"), `/orders/probe-order-1`, `/orders/probe-order-2`,
  `/drivers/aE4Q24u5i0hpP2CEEXz2EjAiBEI2` (created suspended, so never assignable).

**Task B — rows still needing the live stack** (read from `firestore.rules` + `worker/src/admin.js`;
deny confirmed by rule text, round-trip still owed):
- Customer → `/console` deep link: **bounces to `/home`** — `app_router.dart:347-349` (no active
  `/admins` doc ⇒ redirect). Staff deep-linking a section they lack: bounced to `/console`.
  Needs the app running to drive.
- Worker: no token → **401** (`missing_token`), bad token → 401 (`invalid_token`), non-staff or
  inactive or missing perm → **403** `forbidden` — one identical body, never leaking which check
  failed (`admin.js:41-72`).
- Support staff (users.read + orders.read + orders.update): products/config writes denied,
  `/auditLogs` read denied (no `auditlogs.read`), `admins/set` needs `admins.manage` → 403,
  `impersonate` needs `system.impersonate` → 403.
- Admin-role staff vs founder: rank-guarded. `STAFF_ROLE_RANK` = support 40 · moderator 60 ·
  admin 80 · founder 100; `admins/set`, `admins/remove`, and `impersonate` all require the caller
  to **strictly outrank** the target ⇒ admin (80) against founder (100) → 403 on all three.
- Founder break-glass: `isFounder()` is a literal-uid branch on `/orders` read
  (`firestore.rules:192-197`) and is mirrored client-side for `/finance`
  (`app_router.dart:337-341`), so finance survives losing the `/admins` doc. Static-confirmed;
  the doc-rename drill is still a live step.

**Three by-design loosenesses the live matrix must EXPECT (else they read as failures):**
1. `/coupons` — any signed-in user may bump `usedCount` by exactly +1 (checkout redemption).
   So "customer writes to `/coupons` → ALL denied" is wrong as written: create/delete//other-field
   updates are denied, the +1 redemption bump is allowed on purpose.
2. `/drivers` — any signed-in user may move `activeOrdersCount` by ±1 (assignment counting);
   documented as loose, Worker endpoint is the hardening path.
3. `/shops` — any signed-in user may bump `ratingSum`/`ratingCount` by one 1-5 vote (rating).

**One residual finding (low severity, NOT fixed — deliberately). Confirmed LIVE: HTTP 200 on a
self `status: 'banned'` write; the matching role-escalation attempt was correctly 403.** `/users`
self-update (`firestore.rules:47-48`) pins `role` but does not restrict `affectedKeys`, so a
signed-in user can write junk into their own `status` / `deleted` mirror fields. It is **not** a
suspension/deletion bypass: `/admin/users/set-disabled` and `/admin/users/soft-delete` both flip
Firebase Auth `disableUser` and revoke live sessions, so a punished account cannot authenticate at
all, let alone self-restore. Impact is limited to a user desyncing the console's display of their
own doc. The fix is an `affectedKeys().hasOnly([...profile fields])` clause on the self branch —
NOT applied here because the exact self-written field set can only be confirmed against a running
app, and a wrong list silently breaks profile edits at runtime. Do it in the live pass.

**Verdict:** everything verifiable without a seeded console is green — **48 live rule round-trips,
0 failures** (18 customer deny-matrix + 30 state-machine/cross-role), plus green gates and a clean
static sweep. What is still open, and exactly why:
- **Task B staff rows** (support / admin / founder break-glass) — every one needs an `/admins` doc,
  which only the seed can create. Same for the Worker's 401/403 rows: the Worker isn't deployed.
- **Task A** (functional acceptance) and **Task C** journeys — need a seeded, reachable console.
- **Task D** tile alignment + dark-mode chip contrast — need eyes on a running console.
The probe script generalises: once the seed has run, point it at a support-staff and an admin-staff
ID token to clear those rows the same headless way, leaving only the genuinely visual work for a
device/browser pass.
