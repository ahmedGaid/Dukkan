# Dukkan — Master Daily E2E Test Prompt

> **How to use:** paste this whole file as the prompt for an autonomous AI coding agent
> (Claude Code with device access via `adb` + Flutter tooling). It is designed to run
> **unattended, once per day** (or before any release build), as a full regression of the app.
>
> Automation options:
> - Claude Code scheduled routine: `/schedule` a daily local agent whose prompt is
>   `Read and execute Docs/testing/E2E_MASTER_PROMPT.md`.
> - Windows Task Scheduler: `claude -p "Read and execute Docs/testing/E2E_MASTER_PROMPT.md" --permission-mode acceptEdits`
>
> **This file is self-maintaining.** Phase 7 requires the executing agent to update it when new
> features ship. Never delete a journey; mark it `[RETIRED — reason]` instead.

---

## Mission

You are acting as **two real users** — an Egyptian grocery **customer** and a **دكان owner** —
plus a **QA engineer** with backend access. Verify Dukkan end to end: every major flow, through
the real app UI on a device/emulator, with every action verified against **four layers**:

1. **UI state** — the screen shows the result (item in cart, order row appears, status chip changes,
   snackbar confirms).
2. **App runtime** — no uncaught Dart exceptions, no red screens, no BLoC error states, no failed
   HTTP/Firebase calls in `flutter run` logs / logcat during the journey.
3. **Backend data** — the Firestore document actually exists/changed (verify via Firebase CLI or a
   small Dart verify script — see Appendix A).
4. **Business rules** — totals add up, money is **integer piasters** on the wire, cart is per-shop,
   status flow follows `pending → accepted → preparing → outForDelivery → delivered | cancelled | rejected`,
   ar/en parity holds.

A test only PASSES when all four layers agree. A green screen with a silently failed write is a FAIL.

**Fix loop:** when a test fails — investigate root cause in the code, fix it, run the project gates,
rerun the failed journey (and any journey touching the same feature), and repeat until green. Only
skip a fix (mark `SKIPPED-NEEDS-HUMAN`) if it needs a product decision, a paid/console-side Firebase
change, a destructive data operation, or credentials you don't have.

---

## Environment facts (Appendix A — keep current)

| Fact | Value |
|---|---|
| Repo root | `C:\AhmedGaid\Dukkan` |
| Flutter SDK | `C:\src\flutter\bin` — PowerShell: `$env:PATH = "$env:PATH;C:\src\flutter\bin"`; bash: `export PATH="$PATH:/c/src/flutter/bin"` |
| Android SDK | `C:\Android\Sdk` (android-36); JDK 17 at repo-root `jdk-17.0.11_windows-x64_bin/`; adb at repo-root `platform-tools/` |
| Device | Real device `R5CNC0NK6ZT` (Galaxy S21 Ultra, Android 15, arm64). Fallback: any emulator from `flutter devices` |
| Run app | `flutter run -d R5CNC0NK6ZT` (debug). Release check: `flutter build apk --debug --target-platform android-arm64` |
| Firebase project | `dukkan-93042` — Auth + Firestore + FCM. Firebase CLI is logged in |
| Firestore | Database `(default)` — **verify it exists first** (Phase 0); rules deploy: `firebase deploy --only firestore:rules --project dukkan-93042` |
| Backend read/verify | `firebase firestore:*` CLI, or a throwaway Dart script under `lib/dev/` run with `flutter run -t` |
| Seed data | `flutter run -t lib/dev/seed_demo_data.dart -d <device>` (2 demo shops, ~20 products, ≥1 `isPromo: true`) |
| Test accounts | Customer: `ahmedgaid14@gmail.com` (uid `LPPjx32MJpWlMR3SEksJ7sY2NAF2`). Owner: create `e2e-owner-YYYYMMDD@test.dukkan` in-app (role = owner). Passwords in local notes, never in this file |
| Worker (upload + notify) | `worker/` — Cloudflare Worker: `/upload` (R2) + `/notify` (FCM HTTP v1). Base URL in `AppConfig.workerBaseUrl`. If not deployed → related steps are SKIPPED-NEEDS-HUMAN |
| l10n | After editing `app_ar.arb`/`app_en.arb`: `flutter gen-l10n` before analyze |
| Gates (must be green before "fixed") | `flutter analyze` · `flutter test` · `dart run scripts/check_i18n_parity.dart` |
| UI driving | Prefer `integration_test/` harness for repeatable journeys; else drive the live device: `adb shell input tap/text/swipe` + `adb exec-out screencap -p` for screenshots + `flutter run` logs for runtime layer |
| Reports | `Docs/testing/e2e-reports/YYYY-MM-DD/` |

---

## Phase 0 — Boot & health

1. **Toolchain:** `flutter doctor` — Android toolchain + device must be green. Device connected:
   `adb devices` shows `R5CNC0NK6ZT` (ask user to unlock screen if PIN-locked; that is the ONLY
   allowed human touch in this phase).
2. **Firebase health:** confirm Firestore `(default)` DB exists and rules are deployed
   (`firebase firestore:databases:list --project dukkan-93042`). If `(default)` is missing → STOP,
   mark the whole run `BLOCKED` (creating it needs a human region decision — see `dukkan-status`).
3. **Seed check:** shops + products exist (≥2 shops, ≥1 promo product). If empty, run the seed script.
4. Create today's report directory `Docs/testing/e2e-reports/YYYY-MM-DD/` with `screenshots/`.
5. `flutter run -d R5CNC0NK6ZT` and **keep the log attached for the whole run** — any uncaught
   exception, red screen, or Firebase error during a journey fails that journey.
6. Baseline screenshot of the splash + first screen.

## Phase 1 — Smoke: launch, shell, i18n

- **S1 Launch & auth screen:** app launches to splash → login without exceptions. Wrong password →
  designed, blame-free error (no raw `FirebaseAuthException` text, no stack). Correct login → lands
  on Home; `/users/{uid}` role doc loads (no infinite spinner).
- **S2 App shell:** bottom-nav renders all tabs; each tab opens; back button behaves (no dead ends,
  no app exit from inner screens).
- **S3 i18n/RTL:** app in Arabic (default) — layout is RTL, no untranslated keys (raw `key_like_this`
  on screen = FAIL), numerals and prices formatted Egyptian-style. Switch to English in Settings —
  layout mirrors to LTR, reads identically. Switch back. Screenshot both.
- **S4 Theme:** toggle dark mode in Settings — every visited screen renders on-brand in dark
  (no unreadable text, no hardcoded-light surfaces). Screenshot Home light + dark.
- **S5 Navigation sweep:** visit every reachable screen once (Home, shop, product detail, search,
  cart, orders, favorites, settings; owner: shop profile, catalog, order desk). Each renders a
  designed state — data, or designed empty state; never a blank screen or bare "No data". Zero
  exceptions in the run log.

## Phase 2 — Business journeys (the core)

Roles = logins: customer, owner, courier (J13), plus — for the Console journeys J15/J16 — founder,
support-role staff and admin-role staff. Run each journey as the account it names.
Use unique test data prefixed `E2E-YYYYMMDD-` so runs don't collide and cleanup is possible.
Prices must exercise piasters (e.g. 12.50 EGP = `1250`) — verify Firestore holds the **integer**,
never a double (Shoppy lesson; locked decision).

### J1 — Customer signup & profile
1. Sign up a fresh customer `e2e-cust-YYYYMMDD@test.dukkan` with role choice = customer.
2. Verify `/users/{uid}` doc: `role: 'customer'`, name/phone as entered.
3. Log out, log back in — profile loads, role routing correct (customer shell, not owner).

### J2 — Browse (marketplace home)
1. Home shows promo carousel (only `isPromo: true` products), category grid, nearby-shops list.
2. Open a shop: header shows open/closed correctly (flip `isOpen` in Firestore → app reflects it
   on next load; realtime if snapshots are wired). In-shop category filter narrows the grid.
3. Product detail: name ar/en per language, price formatted at the edge, image loads (shimmer
   while loading, designed fallback on broken URL).

### J3 — Search
1. Search a product by Arabic name **with hamza/teh-marbuta variants** (Arabic folding must match).
2. Search by category and by shop name — all three match paths work.
3. Nonsense query → designed no-results state. Empty query → designed prompt state.
4. Typing fast doesn't fire a request per keystroke (debounce — check log for request spam).

### J4 — Cart & checkout (COD)
1. Add 2 different products from shop A (one with quantity > 1 via stepper).
   Cart badge = **distinct products count** (2), not total quantity.
2. Try adding a product from shop B → confirm-and-clear dialog appears; cancel keeps cart A;
   confirm clears and starts cart B. Return to cart A products for the rest.
3. Checkout: manual address entry, COD confirm → order-placed screen.
4. Verify `/orders/{id}`: `items[]` match, `totalMinor` is the **integer sum** of line
   `priceMinor × qty`, `status: 'pending'`, `customerUid` correct, address + notes saved.
5. Line math check: recompute the total yourself from Firestore product prices — must equal
   `totalMinor` exactly (no float drift).

### J5 — Customer orders
1. Orders list shows the J4 order, newest first, optimistically (no reload flash after placing).
2. Order detail: status stepper on `pending`; items and total match.
3. Cancel the order (allowed on pending/accepted only) → status `cancelled` in UI **and** Firestore.
4. Place a second order (for J8). Verify a `delivered` or later-stage order shows NO cancel action.

### J6 — Owner onboarding & shop profile
1. Sign up owner `e2e-owner-YYYYMMDD@test.dukkan` (role = owner) → shop-profile form.
2. Create shop `E2E-YYYYMMDD Shop` (name ar+en, address, open toggle). Logo upload via `image_picker`
   → Worker `/upload` → R2. If Worker not deployed: mark upload step SKIPPED-NEEDS-HUMAN, save shop
   without logo, continue.
3. Verify `/shops/{shopId}`: `ownerUid` = this uid, fields correct. Shop appears in the customer
   home list (log in as customer to confirm, or check the query the home screen uses).

### J7 — Catalog manager
1. As owner: create product `E2E-YYYYMMDD Product`, price 12.50 EGP → Firestore `priceMinor: 1250`
   (integer!), category set, image (same Worker caveat as J6).
2. Edit price → change reflected customer-side. Toggle `stockStatus` → product shows as unavailable
   customer-side (not silently orderable).
3. Set `isPromo: true` → product appears in the customer home promo carousel.
4. Delete (or deactivate) the product → gone from customer browse + search.

### J8 — Order desk (owner) + realtime status
1. As owner: J5's second order appears in incoming orders **in realtime** (Firestore snapshot —
   no manual refresh).
2. Accept → advance `preparing` → `outForDelivery` → `delivered`, one step at a time. Each advance:
   correct next-status only (no skipping), Firestore updated, daily summary strip updates.
3. Customer side: order detail stepper reflects each change in realtime (keep the customer session
   open on the order while advancing, second device/emulator or re-login).
4. Reject flow on a fresh order → `rejected`, customer sees blame-free rejected state.

### J9 — Favorites
1. As customer: favorite a shop and a product. Both appear in Favorites tab.
2. Kill + relaunch app — favorites persist. Unfavorite → row leaves the list without reload flash.

### J10 — Notifications (FCM)
1. Verify FCM token saved at `/users/{uid}.fcmToken` after login.
2. If Worker `/notify` deployed: advance an order status as owner → customer device receives push
   (foreground snackbar via root messenger; background tap navigates `statusUpdate` → `/order/:id`).
   New order as customer → owner receives `newOrder` push → tap navigates to `/home`.
3. Push text is bilingual ("$ar / $en"). Worker rejects a caller who is not a party to the order
   (probe with the wrong account's token → expect 403, not a send).
4. Worker not deployed → SKIPPED-NEEDS-HUMAN (token check in step 1 still runs).

### J11 — Ratings
1. As customer with a `delivered` order: rate the shop. Rating stored; shop card average updates.
2. No rating prompt on non-delivered orders. Re-rating behaves per rules (update, not duplicate).

### J12 — Settings
1. Profile shows correct user data. Language + theme switches persist across app restart.
2. Logout → back to login; protected routes unreachable (deep-link probe: `adb shell am start`
   with an order route while logged out → lands on login, not a crash).

### J13 — Drivers (M8–M11, shared pool)
1. Courier signup → profile starts `suspended`; app blocks courier shell until founder activates
   via console (`/drivers/{uid}.suspended = false`). Online switch works once active.
2. Owner assignment sheet on a `preparing` order lists only online + active + non-suspended +
   in-area + under-capacity drivers; each row shows areas + `n / max` occupancy.
3. Race check: two shops racing to assign the same near-capacity driver — the loser gets a clear
   Arabic rejection (capacity), not a corrupted assignment (transaction correctness).
4. Reject paths: offline driver, wrong-area driver, already-taken order — each a clear Arabic
   message, no partial write.
5. Same driver stays visible/assignable to a second shop until capacity fills; `n / max` increments
   on assignment and decrements correctly on both `delivered` and `cancelled`.
6. Courier device: advances `preparing → outForDelivery → delivered` only, no skip, no
   out-of-order transition. Owner self-delivery (no driver) still works unchanged end to end.
7. Assignment push received on the courier device (or logged as
   `SKIPPED-NEEDS-HUMAN — Worker not deployed` if the Worker isn't live).

### J14 — Commission + finance (M12–M13)
1. Place a new order → Firestore order doc snapshots `commissionBps` + the computed commission
   amount (round-half-up, integer piasters) from `/config/platform` at creation time — never
   recomputed later.
2. Advance to `delivered` → commission flips to payable. Cancel a `pending`/`accepted` order →
   commission never becomes payable.
3. Change `/config/platform` rate → only orders placed **after** the change use the new bps;
   already-snapshotted orders are unaffected.
4. Finance page (`/finance`, founder account only): non-founder account is bounced by the router;
   rules deny a non-founder aggregate read even via direct query. Founder sees six metrics, all
   **delivered-only** sums, with the COD-ledger note visible and correct.

### J15 — Founder Console «إدارة»: functional (FC1–FC17)
> Desktop-first (`flutter run -d windows`), then spot-check the same flows at phone width.
> Needs: founder `/admins` doc seeded, rules+indexes deployed, Worker deployed. Any step whose
> only blocker is the Worker → `SKIPPED-NEEDS-HUMAN — Worker not deployed`.
1. **Access + shell (FC1/FC3):** founder sees the «لوحة التحكم» row in Settings; `/console` opens
   the rail ≥900px and the drawer below; the staff chip names the role. A non-staff account has no
   row and `/console` bounces to `/home`.
2. **Dashboard (FC5):** every tile shows a real number (not «—» for a permission the founder has);
   the 7-day bar chart is plausible against seeded orders; 60s auto-refresh and pull-refresh both
   repaint; the recent-activity strip links into `/console/audit`.
3. **Audit log (FC4):** every mutation below writes an entry — filter by action/type/targetId/date,
   paginate past 30 rows, open the detail sheet and confirm the before/after diff matches what you
   just changed. `write: false` holds: no client can create an entry.
4. **Users (FC6):** search by exact email → detail → suspend/unsuspend (session revoked) → change
   email → persona-role change → staff role grant/revoke → soft delete/restore.
5. **Shops (FC7):** a `pending` shop is invisible on the customer home → approve → it appears;
   suspend → it disappears from home + search; featured/verified toggles; ownership transfer
   (Worker); create-shop-for-owner.
6. **Products (FC8):** cross-shop board filters; edit via the owner form and confirm
   `isFeatured`/soft-delete fields survive; duplicate; soft delete/restore; bulk +10% on three
   products with hand-verified round-half-up; bulk category move; founder-only hard delete.
7. **Taxonomy (FC9):** add → hide → reorder a category; the product form's dropdown follows;
   pre-delete product-count warning appears; a retired category is `isVisible:false`, not deleted.
8. **Geo (FC9):** add an area → checkout offers it; set a fee override → a NEW order snapshots that
   fee, not `/config/platform`'s; deactivate → checkout drops it; an area with orders refuses to
   delete and offers deactivate instead.
9. **Orders (FC10):** board status filters; staff detail via `?role=staff`; force-status with a
   reason (timeline row shows «تصحيح إداري»); force `delivered → preparing → delivered` and confirm
   the driver's `activeOrdersCount` decrements ONCE; reassign driver (counts move on both drivers);
   internal note is realtime for staff and invisible to customer/owner/courier.
10. **Drivers (FC11):** activate the suspended seed driver → it appears in the owner assignment
    sheet; suspend with a reason → the courier shell shows the suspended banner; verified toggle;
    areas multi-select; capacity stepper; ID-doc upload lands in R2 (Worker).
11. **Settings (FC12):** commission edit affects the NEXT order only; maintenance mode blocks a
    customer and passes a staff account; `minSupportedBuild` above `AppConfig.buildNumber` shows
    `/update-required`; a feature flag toggle reads back through the helper. Each card shows «آخر
    تعديل» from the newest matching audit entry.
12. **Notifications (FC13):** broadcast to the customer topic arrives on customers ONLY; direct
    send to one user; a template pre-fills compose; history shows sent/failed counts and a failed
    row resends. (Worker.)
13. **Media (FC14):** browse each folder with pagination; stats cross-check the grid; the
    unused/broken finders are truthful against a deliberately orphaned upload; bulk hard delete.
    (Worker.)
14. **Impersonation (FC15):** enter as a customer → the banner shows on every screen → act → exit
    → the founder session is restored; both audit entries present; kill the app mid-impersonation
    and relaunch → the banner still derives from the ID token claim (no lost session).
15. **Devtools (FC15):** health checks green; test notification; fake customers/orders generate then
    clean up fully; running a migration twice is idempotent.
16. **Promos (FC16):** coupon lifecycle at checkout — apply (percent, hand-verify round-half-up),
    reject each `CouponRejectReason` with its own Arabic copy, place the order, confirm
    `usedCount` +1 and that commission is computed on the PRE-discount subtotal; an active banner
    appears first in the home carousel and taps through to its target; a featured shop shows in
    «دكاكين مميزة».
17. **Search / exports / reports (FC17):** Ctrl+K finds each entity type (Arabic-folded, keyboard
    nav, permission-gated groups); a CSV export of a filtered board opens in Excel with Arabic
    intact and matches the on-screen filter; `/console/reports` totals cross-check the dashboard
    and the finance page.
18. **Sweep:** repeat 2/4/6/9/17 at phone width (drawer nav), in dark mode, and in English — no
    overflow, no bare English string in Arabic, no physical left/right RTL bug.

### J16 — Founder Console «إدارة»: security matrix (FC1–FC17)
> The point of the whole Console plan: every deny below must actually deny. Needs four accounts —
> founder, support-role staff (`users.read` + `orders.read` + `orders.update` only), admin-role
> staff, plain customer.
1. **As customer:** `/console` deep link bounces to `/home` and Settings shows no console row.
2. **As customer, direct Firestore writes** (debug script or a temporary button) to `/admins`,
   `/roles`, `/auditLogs`, `/config`, `/categories`, `/areas`, `/coupons`, and another user's
   `/users` doc → ALL denied.
3. **As customer, Worker:** `/admin/ping`, `/admin/users/set-disabled`, `/admin/impersonate` with
   the customer's ID token → 403; with no token → 401.
4. **As customer, cross-user reads:** another customer's order → denied; `/auditLogs` → denied.
5. **As support staff:** the console shows only the sections its perms allow; every hidden
   section's route bounces to `/console`; Firestore writes to `/products` and `/config` → denied;
   Worker `admins/set` → 403; `impersonate` → 403.
6. **As support staff:** `/auditLogs` read → denied (no `auditlogs.read`) AND the section is
   absent — rules and UI agree.
7. **As admin staff:** cannot touch the founder — `admins/set` on the founder → 403, impersonate
   the founder → 403 (rank guard).
8. **Founder break-glass:** temporarily rename the founder's `/admins` doc id via the console →
   `/finance` still opens on the `isFounder()` literal → restore the doc. Proves the bootstrap
   path survives a wiped `/admins`.

## Phase 3 — Cross-cutting quality sweeps

- **C1 Runtime log review:** compile every exception/error captured since Phase 0 from `flutter run`
  logs + `adb logcat` (package-filtered). Each unique one is a finding (dedupe by message).
- **C2 Offline behavior (Shoppy lessons):** airplane mode ON → browse previously-seen shops/products
  from local cache (no infinite spinner, designed offline/error state where no cache); actions that
  need network fail gracefully. Airplane OFF → app recovers without restart. Rule:
  `online → remote, offline → local cache` — no TTL games.
- **C3 Designed states:** confirm one loading (shimmer), one empty (fresh filter/no favorites),
  one error state (offline from C2) are all designed — never bare text or a spinner forever.
- **C4 Visual/brand spot-check (AR/RTL + both themes):** mint/deep-green palette only from theme
  tokens (AppColors), rounded type, spacing/radius from scale; RTL has no physical left/right bugs.
  Screenshots: Home, shop page, cart, order detail — AR/dark + AR/light (+ EN/light for parity) —
  run against the `dukkan-brand` checklist. Bar: *"would a دكان owner brag about it?"*
- **C5 Performance:** cold start to Home < 4s on device; tab switches feel instant; scrolling a
  full product grid doesn't jank (watch for frame-skip warnings in logs). Log regressions vs. the
  previous report if one exists.
- **C6 Data hygiene:** every money field in Firestore is an integer (query a sample of products +
  orders); no `null`/`NaN`/`undefined` rendered anywhere; dates localized.

## Phase 4 — New-feature discovery (keeps the suite current)

1. `git log --oneline --since=<date-of-last-report>` (fall back to 7 days). Also skim
   `Docs/plan/dukkan-roadmap.md` for freshly completed session-blocks.
2. Every user-facing feature shipped since the last run with **no journey above**: test it now
   (same four-layer standard) and **add a numbered journey to Phase 2 of this file** in the same
   format. Mandatory — the suite must grow with the app.
3. Note additions in the report under "Suite changes".

## Phase 5 — Fix loop (on any failure)

For each FAIL, in severity order (data corruption > broken flow > crash/exception > visual > perf):

1. **Reproduce** minimally. Capture screenshot + run-log excerpt + the failing Firestore state.
2. **Root cause** in code — read the actual BLoC/repository/datasource; don't patch symptoms.
3. **Fix** following project rules (`dukkan-flutter` skill: Clean Architecture layers, BLoC rules,
   integer piasters, i18n parity, no new deps without asking).
4. **Gate:** `flutter analyze` · `flutter test` · `dart run scripts/check_i18n_parity.dart`.
5. **Rerun** the failed journey plus every journey in the same feature. Repeat until green.
6. Record in the report: root cause, files changed. Commit with a conventional message
   (`fix(feature): ...`) — one commit per root cause. Do not push.

If a fix is destructive, needs a product decision, or needs Firebase-console/paid changes →
`SKIPPED-NEEDS-HUMAN` with a clear handoff note; continue.

## Phase 6 — Release-build re-verify

Only when **all debug journeys pass** (no FAILs; SKIPPED-NEEDS-HUMAN allowed):

1. Build release-mode APK: `flutter build apk --release --target-platform android-arm64`
   (uses `android/key.properties` if present, else debug signing — see `Docs/RELEASE.md`).
2. Install on the device (`adb install -r`) and rerun **Phase 1 fully** + an abridged Phase 2
   (J2, J4, J8 — the highest-value flows). Release mode catches tree-shaking/minify/timing bugs
   debug mode hides.
3. Release-only failures → fix loop again, rebuild, re-verify. Then uninstall the release build
   and restore the debug install.

## Phase 7 — Report & self-maintenance

Write `Docs/testing/e2e-reports/YYYY-MM-DD/report.md`:

```markdown
# Dukkan E2E Report — YYYY-MM-DD
**Summary:** X passed · Y failed→fixed · Z skipped-needs-human · W new journeys added
**Verdict:** GREEN / GREEN-WITH-SKIPS / RED (why)

## Results by journey
| Journey | Result | Notes |
(one row per S/J/C item; link screenshots)

## Failures & fixes
(per failure: symptom → root cause → fix → files → gates rerun → rerun result)

## Skipped — needs human
(what, why, exact handoff)

## Suite changes
(journeys added/updated in the master prompt today)

## Performance
(timings vs previous run)

## Environment
(commit SHA tested, device, debug + release results)
```

Then **maintain this master prompt**:
- Add the new journeys from Phase 4 (already done in place).
- Update Appendix A if any environment fact changed (device, project id, commands, gates).
- Never delete a journey — mark `[RETIRED — reason, date]`.
- Keep the test-data prefix convention and the four-layer standard intact.

Finally: clean up test data where a delete flow exists in the UI (use it — that's a test too);
otherwise delete `E2E-YYYYMMDD-` Firestore docs via CLI and note it in the report. Never touch
non-prefixed (seed/real) data.

---

## Hard rules for the executing agent

- **Never fake a pass.** No screenshot + four-layer verification = not a pass.
- **UI first.** Drive the app like a human (tap, type, swipe). Firestore/CLI reads are for
  *verification*, never a substitute for the UI action.
- **Arabic first.** Run journeys in Arabic/RTL by default; S3 covers English parity.
- **Don't skip gates to save time** — green gates are part of "fixed".
- **Never reset/wipe Firestore or Auth.** Additive test data only, prefixed `E2E-YYYYMMDD-`.
- **One commit per root cause; never push; never merge.**
- **Respect the brand bar** when fixing UI: would a دكان owner brag about it?
