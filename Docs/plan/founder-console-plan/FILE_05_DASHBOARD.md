# SESSION 5 — Dashboard: live stats, activity, quick actions
# Files: lib/domain/dashboard/** (new), lib/data/dashboard/** (new),
#        lib/presentation/console/dashboard/** (replaces session-3 placeholder body),
#        lib/core/di/injector.dart, firestore.indexes.json,
#        lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/data/finance/datasources/` — the M13 aggregate-query pattern
   (`count()`, `sum()`, `Future.wait`, no doc downloads). The dashboard datasource is a
   wider version of exactly this.
2. Open `lib/presentation/finance/pages/finance_page.dart` — stat-tile grid + shimmer +
   error states to reuse (extract shared widgets rather than copy-pasting: move the tile
   into `lib/presentation/console/widgets/stat_tile.dart` and make FinancePage use it too).
3. Open `lib/domain/order/entities/order.dart` — confirm `createdAt` field type (Timestamp).

Do not write anything yet.

---

## Task A — Dashboard aggregates

`lib/domain/dashboard/entities/dashboard_summary.dart` + repository + `GetDashboardSummary`
use case; datasource runs via `Future.wait`:

- ordersToday: `orders.where(createdAt >= startOfToday).count()`
- revenueTodayMinor: delivered today → `sum(totalMinor)`
- commissionTodayMinor: delivered today → `sum(commissionMinor)`
- ordersWaiting: `status == 'pending'` count
- totalUsers / totalShops / totalProducts: collection `count()`s
- driversOnline: `isOnline == true && isSuspended == false` count
- pendingShops: `shops.status == 'pending'` count (0 until Session 7 introduces the field —
  fine, equality query on a missing field just matches nothing)
- last7Days: 7 per-day order counts (loop of count queries — cheap, no downloads)

Indexes: check which combos need composites (`status + createdAt`; drivers
`isOnline + isSuspended` exists from M8/M9 — verify in `firestore.indexes.json`, add the
missing ones).

Rules dependency: users/orders count queries ride the `hasPerm('users.read')` /
`hasPerm('orders.read')` read branches from Session 1 — both auth-only, so aggregates work.

## Task B — Dashboard page

Replace the Session-3 placeholder body:
- **Stat grid** (2-col phone / 4-col ≥ 900): the nine tiles above; money via `PriceTag`
  recolored `onSurface` (M13 finance style — calm monochrome, no accent).
- **7-day bar chart**: `CustomPaint` mini bar chart widget
  `lib/presentation/console/widgets/mini_bar_chart.dart` (no new dep) — bars = daily order
  counts, labels = weekday initials, theme colors only.
- **Recent activity**: last 10 audit entries (reuse Session 4 repo with page size 10),
  row tap → `/console/audit`.
- **Quick actions** row: chips → orders waiting (`/console/orders?status=pending`,
  route from Session 10 — chip hidden until that route exists; same pattern for drivers/
  broadcast chips landing later; wire what exists now: audit).
- Pull-to-refresh + auto-refresh every 60 s (Timer in bloc, cancelled on close).
- `DashboardBloc`: single load event reused by start/refresh (FinanceBloc pattern).
- Storage usage / failed notifications / crash summary tiles: NOT now — sessions 14/13
  add their tiles; Crashlytics stays external (show a static "Crashlytics" row with the
  console URL as selectable text — no url_launcher dep).

i18n: every tile label, chart caption, activity header — both ARBs.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Bloc test: summary load success/failure emits (fake repo).
- [ ] Datasource test for the date-window math (startOfToday in local tz → UTC Timestamp).
- [ ] On device/desktop as founder: real numbers match reality (compare one count by hand
      in the app, e.g. orders list length); refresh works; tiles show "—" + error state on
      airplane mode, retry recovers.
- [ ] Non-staff never reaches the page (guard from Session 3 still holds).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_06_USER_MANAGEMENT.md
User action: deploy any new indexes.
```
