# SESSION 6 — User Management: list, detail, auth ops via Worker, staff management
# Files: worker/src/admin.js, firestore.rules, lib/domain/admin/** (extend),
#        lib/data/admin/** (extend), lib/presentation/console/users/** (new),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `worker/src/admin.js` — routes map + `requireAdmin` + `writeAudit`.
2. Open `firestore.rules` — `/users` block (session-1 read branch present).
3. Open `lib/domain/auth/entities/app_user.dart` — current user fields.
4. Open the orders repository — the query-by-`customerUid` used by the customer orders
   list (reused on the user detail page).
5. Check whether `/users` docs have `createdAt` — signup path in the auth datasource.
   (If absent: pagination cursor = documentId, and Task E's signup change adds `createdAt`
   for new users.)

Do not write anything yet.

---

## Task A — Worker user endpoints

Add to the `routes` map (each writes an audit entry with before/after where sensible):

| Route | Perm | Does |
|---|---|---|
| `/admin/users/set-disabled` | users.update | Identity Toolkit `accounts:update` `{localId, disableUser}` + revoke sessions (`validSince: now`) + patch `/users/{uid}.status` (`'suspended'`/`'banned'`/`'active'` from body) |
| `/admin/users/set-persona-role` | users.update | patch `/users/{uid}.role` — value ∈ customer/owner/courier ONLY (staff roles live in `/admins`, reject others) |
| `/admin/users/change-email` | users.update | `accounts:update` `{localId, email}` + patch `/users` doc email |
| `/admin/users/soft-delete` | users.delete | patch `deleted: true, deletedAt, deletedBy` + `disableUser: true` |
| `/admin/users/restore` | users.delete | clear the three fields + `disableUser: false` |
| `/admin/users/create` | users.create | `accounts:signUp` (email+password from body) + create `/users` doc (name, role, createdAt) |
| `/admin/users/lookup` | users.read | `accounts:lookup` by localId → `{email, emailVerified, disabled, lastLoginAt, createdAt}` (login history on detail page) |
| `/admin/admins/set` | admins.manage | create/update `/admins/{uid}`: body `{uid, role, extraPermissions[]}` → read `/roles/{role}`, **denormalize** `permissions = role.permissions ∪ extras`, set rank from role. **Rank guard: caller.rank must be > target's current AND new rank** (admin can't touch founder or promote to founder) |
| `/admin/admins/remove` | admins.manage | delete `/admins/{uid}` (same rank guard) |

Identity Toolkit calls: `https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/…`
with the service-account bearer (scope added in Session 2). Password reset email is NOT an
admin endpoint — the client SDK `sendPasswordResetEmail` does it (Task D).

## Task B — Rules

`/users` update: keep the self-edit branch; add
`|| (hasPerm('users.update') && request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['name', 'phone', 'status', 'deleted', 'deletedAt', 'deletedBy']))`
— role/email changes stay Worker-only.

## Task C — Domain/data extensions

Extend the admin vertical: `AdminUserActions` repository interface (one method per Worker
endpoint) + impl calling `AdminApiDataSource.post`; `AuthLookup` entity for
`/admin/users/lookup`. Use cases per action (thin, GetFinanceSummary shape). Paginated
user list: `AdminUsersRepository.getUsers({role?, status?, cursor})` — Firestore-direct
reads (rules allow users.read), page 25, orderBy documentId; plus `getByEmail(exact)` /
`getByPhone(exact)`.

## Task D — Console UI

- `/console/users` (`consoleSections` + router): search field (exact email / exact phone /
  else name contains on the loaded page — label the limitation in the field hint), role +
  status filter chips, paginated list. Row: name, email, persona role chip, status chip,
  deleted strikethrough.
- Detail page `/console/users/:uid`: profile card (+ auth card from `lookup`: verified,
  disabled, last login) · actions (suspend/unsuspend, ban, reset-password email via client
  SDK `sendPasswordResetEmail(email)`, change email dialog, persona role dialog, soft
  delete/restore — each destructive one behind a confirm dialog stating exactly what
  happens) · staff card: current `/admins` role or "not staff", `admins.manage` holders get
  role dropdown + extra-permissions checklist (from `Permissions` constants) → `admins/set`
  · orders list (query customerUid) · shops list (query ownerUid) · audit history
  (Session 4 repo filtered `targetType: 'user', targetId: uid`).
- After every Worker action: optimistic UI + `reportAudit` NOT needed (Worker audited) —
  just refresh the row.
- Bulk v1: multi-select → bulk suspend/unsuspend (loop over set-disabled; progress dialog;
  summary snackbar "12/12 تم"). Export/import buttons deferred to Session 17.
- Audit actions list: append `user.disable`, `user.enable`, `user.softDelete`,
  `user.restore`, `user.create`, `user.changeEmail`, `user.setRole`, `admin.set`,
  `admin.remove` to `audit_actions.dart`.

## Task E — createdAt on signup

In the auth signup datasource, add `createdAt: FieldValue.serverTimestamp()` to the
`/users` doc create (additive; old docs stay valid — reports in Session 17 label missing
ones as "before tracking").

i18n: all of it, both ARBs. Lexicon rows: Suspend → إيقاف مؤقت · Ban → حظر ·
Restore → استرجاع.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] wrangler dev: suspend a test user → Firebase sign-in for them fails, `/users.status`
      flips, audit entry `reported:false` exists; restore works.
- [ ] Rank guard: admin-role token calling `admins/set` on the founder → 403.
- [ ] `users/set-persona-role` with `role: 'founder'` → 400/403 (persona whitelist).
- [ ] Console: search by exact email finds the user; suspend/unsuspend round-trip from the
      detail page; support-role account sees the list (users.read) but no destructive
      actions (users.update-gated buttons hidden AND Worker would 403).
- [ ] Reset-password email arrives for a real test address.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_07_SHOP_MANAGEMENT.md
User action: deploy rules; wrangler deploy.
```
