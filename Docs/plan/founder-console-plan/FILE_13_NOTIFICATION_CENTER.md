# SESSION 13 — Notification Center: broadcast, targeted push, history, templates
# Files: worker/src/admin.js, worker/src/firebase.js, firestore.rules,
#        FCM setup file from P2b (topic subscribe), lib/domain/notifications_admin/** (new),
#        lib/data/notifications_admin/** (new), lib/presentation/console/notifications/** (new),
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. `grep -r "FirebaseMessaging" lib/` — open the P2b FCM setup (token save, permission
   request). Topic subscription hooks in there.
2. Open `worker/src/firebase.js` — `sendFcm` (token-based today).
3. Open `worker/src/admin.js` — routes map + `writeAudit`.
4. Open how AuthBloc knows role at login (topic name depends on it).

Do not write anything yet.

---

## Task A — App: role topics

At the point the FCM token is saved after login, also
`FirebaseMessaging.instance.subscribeToTopic('role-${role.wire}')`; on logout,
unsubscribe. One-time migration concern: existing installs subscribe on next login —
acceptable (note it). Locked decision: broadcast content is **Arabic** v1 (app is
Arabic-first; per-locale topics deferred).

## Task B — Worker endpoints

Extend `sendFcm` to accept `{topic}` OR `{token}` (message envelope differs only in that
field). Routes:

| Route | Perm | Does |
|---|---|---|
| `/admin/notify/broadcast` | notifications.send | body `{audience: 'customers'\|'owners'\|'couriers'\|'all', title, body}`. audience→topic (`all` = the three topics sequentially). Writes history doc + audit |
| `/admin/notify/user` | notifications.send | body `{uid, title, body}` → `/users/{uid}.fcmToken` → token send (no token → `{ok, skipped}`); history + audit |

History doc `/notifications/{id}` (Worker-written):
`{kind: 'broadcast'|'direct', audience?, targetUid?, title, body, sentBy, sentAt,
status: 'sent'|'failed'|'skipped', error?}`. On FCM failure write `status:'failed'` +
error string (retry = console re-submits the same content as a NEW send — simple,
auditable; no in-place retry state machine).

Rules:

```
    match /notifications/{id} {
      allow read: if hasPerm('notifications.send');
      allow write: if false;      // Worker-only
    }
    match /notificationTemplates/{id} {
      allow read, write: if hasPerm('notifications.send');
    }
```

## Task C — Console UI

`/console/notifications` (section perm notifications.send), two tabs:
- **إرسال**: audience segmented control (العملاء/أصحاب الدكاكين/المناديب/الكل/مستخدم محدد —
  the last opens a user search reusing Session 6's exact-email/phone lookup), title +
  body fields (counter, FCM ~1000-char practical cap), template picker chip row
  (tap fills the fields), preview card styled like a real notification, send button
  behind a confirm dialog stating the audience size is unknown for topics (honest copy).
- **السجل**: history list (kind icon, audience/target, title, status chip, time), failed
  rows get a resend button; header stat chips: sent/failed counts (aggregate count queries).
- Templates managed inline: save-as-template button after composing; long-press template
  chip → rename/delete sheet. `/notificationTemplates` docs `{name, title, body}` —
  Firestore-direct (rules above) + `reportAudit` (`template.save`, `template.delete`).
- Audit actions appended: `notify.broadcast`, `notify.direct` (Worker-side),
  `template.save`, `template.delete`.
- Dashboard tile: failed notifications count (last 7 days) — add to Session 5's grid now.
- Scheduled notifications: OPTIONAL Task D — skip by default. (If ever needed: wrangler
  `[triggers] crons`, `/scheduledNotifications` collection, Worker `scheduled()` handler
  scanning due docs. Parked, not built.)

i18n both ARBs. Lexicon row: Broadcast → إشعار عام.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Device: customer login subscribes to `role-customer` (log line); broadcast to
      customers from console (wrangler dev or deployed) → arrives on the customer device;
      does NOT arrive on the owner device.
- [ ] Direct send to a specific uid arrives; to a token-less user → history `skipped`.
- [ ] History rows appear with correct status; a forced failure (bad token seeded by hand)
      → `failed` + resend works.
- [ ] Template save → appears in picker → fills compose fields.
- [ ] Non-notifications.send staff: section hidden, Worker 403, history read denied.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_14_MEDIA_LIBRARY.md
User action: deploy rules; wrangler deploy.
```
