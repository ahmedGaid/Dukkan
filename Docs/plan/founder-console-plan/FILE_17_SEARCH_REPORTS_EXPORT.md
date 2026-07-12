# SESSION 17 — Global Search, CSV Export, Reports
# Files: lib/presentation/console/search/** (new), lib/presentation/console/util/csv_exporter.dart (new),
#        lib/presentation/console/reports/** (new), console shell (Ctrl+K wiring),
#        export buttons on users/shops/products/orders boards,
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open the console shell's `Shortcuts` scaffold (Session 3) — the unbound `SearchIntent`.
2. Open the C2c Arabic-folding search util (`grep -r "fold" lib/` or the SearchBloc) —
   reuse, don't re-implement.
3. Open Session 5's `mini_bar_chart.dart` — reports reuse it.
4. Open the users/orders/products/shops board blocs — each needs an "export current
   filter" hook.

Do not write anything yet.

---

## Task A — Global search (Ctrl+K)

`ConsoleSearchDialog` opened by Ctrl+K (bind the Session-3 `SearchIntent`) AND a search
icon in the shell top bar (phone has no Ctrl+K):
- Single field, 300 ms debounce, then PARALLEL lookups (each independent, failures
  collapse to empty — `Future.wait` with per-future catch):
  - order: doc get by exact id
  - users: exact email, exact phone, name prefix (limit 5)
  - shops: nameAr/name prefix, Arabic-folded client filter (limit 5)
  - products: name prefix folded (limit 5)
  - drivers: exact phone, name prefix (limit 5)
  - areas/categories: client filter over the cached lists
- Grouped results («المستخدمون», «الطلبات»…) with type icons; keyboard: ↑↓ + Enter
  navigates; each hit routes to its console detail (order → `/order/:id?role=staff`).
- Permission-aware: only query what `adminProfile.can(...)` allows; groups the caller
  can't read never appear.

## Task B — CSV exporter

`lib/presentation/console/util/csv_exporter.dart`:
- `String toCsv(List<List<String>> rows)` — RFC 4180 quoting; prepend **UTF-8 BOM**
  (`﻿`) so Excel opens Arabic correctly.
- `Future<String> saveCsv(String name, String csv)` — desktop: `Downloads/` via dart:io
  (`Platform.environment['USERPROFILE']`/HOME fallback); mobile: app documents dir;
  returns the path, shown in a snackbar as selectable text (no share dep).
- Wire an export action (perm reports.export) into the four boards: exports the CURRENT
  filter result, paginating through up to 1000 docs (progress dialog, hard cap + honest
  «تم تصدير أول 1000» note). Columns per entity defined next to each board's bloc.
  Money columns in EGP formatted at the edge (they're for humans/Excel).
- Audit each export (`report.export`, after = `{entity, count}`).
- Excel/PDF: NOT built (locked deferral — CSV+BOM opens in Excel).
- Import (users/products bulk import): NOT built — needs file_picker dep + validation
  design; parked with a note. Ask before adding the dep if ever prioritized.

## Task C — Reports page

`/console/reports` (section perm reports.export):
- Period picker (7/30/90 days) → per-day loop of aggregate queries (orders count,
  delivered revenue sum, commission sum — reuse the Session 5 datasource generalized to
  a date range) → three `mini_bar_chart`s + totals row.
- **النمو**: new users per period (`users.where(createdAt >= …)` count — Session 6 added
  createdAt at signup; docs without it are excluded and the caption says
  «قبل بدء التتبّع غير مشمول»), new shops per period (shops lack createdAt — add it to
  onboarding create now, additive, same caveat).
- **التوزيع**: orders by area (count per active area), products by category (count per
  visible category), orders by shop top-10 — simple horizontal bar rows (count + label),
  no new chart types.
- Every table exportable via Task B.
- Retention/activity cohorts: NOT built (locked deferral).

i18n both ARBs. Lexicon row: Report → تقرير.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Unit tests: `toCsv` quoting (comma, quote, newline, Arabic), BOM present.
- [ ] Ctrl+K on desktop finds: an order by full id, a user by email, a shop by partial
      Arabic name (folded); Enter navigates; support-role sees only permitted groups.
- [ ] Export orders (status filter applied) → file opens in Excel with readable Arabic,
      row count matches the board.
- [ ] Reports: 7-day totals match the dashboard tiles for today; area/category breakdowns
      sum to the totals (spot check).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_18_ACCEPTANCE.md
```
