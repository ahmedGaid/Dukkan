# SESSION 4 — Audit Log: immutable trail + console viewer
# Files: firestore.rules, firestore.indexes.json, worker/src/admin.js,
#        lib/domain/audit/** (new), lib/data/audit/** (new),
#        lib/presentation/console/audit/** (new), lib/core/di/injector.dart,
#        lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `worker/src/admin.js` — `writeAudit` + `handleClientAudit` from Session 2; the doc
   shape written there IS the schema (actorUid, action, targetType, targetId, before,
   after, reason, reported, ip, createdAt ISO string).
2. Open `lib/data/finance/` — copy its no-cache repository shape.
3. Open `lib/presentation/orders/` list page — copy its paginated-list + designed-states style.
4. Open `firestore.indexes.json` — note the existing composite-index format.

Do not write anything yet.

---

## Task A — Rules + indexes

`firestore.rules`, new block before the deny-all:

```
    // Audit trail (Founder Console session 4). Immutable by construction:
    // ONLY the Worker writes (service account bypasses rules); clients can
    // never create/update/delete — including staff. reported:true entries are
    // client-reported (best-effort); reported:false were performed server-side.
    match /auditLogs/{entryId} {
      allow read: if hasPerm('auditlogs.read');
      allow write: if false;
    }
```

`firestore.indexes.json`: add composites — `auditLogs(targetType asc, createdAt desc)`,
`auditLogs(actorUid asc, createdAt desc)`, `auditLogs(action asc, createdAt desc)`.
(Single-field `createdAt desc` needs no composite.)

## Task B — Domain + data vertical

- `lib/domain/audit/entities/audit_entry.dart` — fields per schema above; `before`/`after`
  as `Map<String, dynamic>?`.
- `lib/domain/audit/repositories/audit_repository.dart` —
  `Future<List<AuditEntry>> getEntries({AuditFilter filter, DocumentSnapshot? cursor})`
  — page size 30, newest first. `AuditFilter` value object: `action?`, `targetType?`,
  `actorUid?`, `targetId?`, `from?`, `to?`.
- Use case `GetAuditEntries`. Data side: model + remote datasource building the Firestore
  query from the filter (each optional `where` + `orderBy createdAt desc` + `startAfter`).
  Note: `createdAt` is an ISO STRING (Worker writes ISO) — string order == time order for
  ISO-8601 UTC, so orderBy works; parse to DateTime in the model.
- Register in `injector.dart`.

## Task C — Console audit page

`lib/presentation/console/audit/pages/audit_log_page.dart` + `AuditLogBloc`
(load / loadMore / filterChanged events):
- Filter bar: action dropdown (distinct known actions — constants list in
  `lib/domain/audit/entities/audit_actions.dart`, e.g. `user.disable`, `shop.transfer`,
  `order.forceStatus`, `settings.update`, `impersonation.start`… sessions 6–17 append
  here), targetType dropdown, targetId text field, date range picker.
- List rows: leading icon by targetType, `action` + target, actor, relative time,
  `reported` chip when true («مُبلّغ» — best-effort marker).
- Row tap → detail bottom sheet: full fields + before/after rendered as an aligned
  key → old → new table (only changed keys), reason, ip.
- Designed empty ("لا توجد سجلات بعد") / error+retry / shimmer loading states.
- Register section in `console_sections.dart` (`/console/audit`, perm auditlogs.read) +
  route in `app_router.dart` inside the console ShellRoute.

i18n: all labels/states both ARBs. Lexicon row: Audit log → سجل التدقيق.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Unit tests: AuditEntry model parse (full + minimal doc), filter → query mapping
      (fake firestore or datasource-level test per existing datasource-test style).
- [ ] Seed one entry via `POST /admin/audit` (wrangler dev) → appears in the console page.
- [ ] Filters narrow the list; pagination loads a second page (seed 35 dummy entries via
      a temporary loop in wrangler dev or the seed script).
- [ ] Non-`auditlogs.read` staff: section hidden AND direct route bounces (guard) AND
      Firestore read denied (rules — verify once rules deployed).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_05_DASHBOARD.md
User action: deploy rules + indexes.
```
