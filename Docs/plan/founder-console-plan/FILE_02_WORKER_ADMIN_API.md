# SESSION 2 — Worker Admin API: middleware, write helpers, audit writer
# Files: worker/src/index.js, worker/src/firebase.js (new), worker/src/admin.js (new),
#        worker/wrangler.toml (scopes note only), lib/data/admin/datasources/admin_api_datasource.dart (new),
#        lib/core/di/injector.dart, test/

---

## Before You Start

1. Read `worker/src/index.js` fully — you will MOVE (not rewrite) `verifyFirebaseToken`,
   `googleCerts`, `parseMaxAge`, `getServiceAccountToken`, `firestoreGetFields`, `sendFcm`,
   `b64urlDecode`, `bearer`, `json` into a shared module.
2. Note `SA_SCOPES` (line ~45) — datastore + messaging today.
3. In the Flutter app run `grep -r "workerBaseUrl" lib/` — open the datasource that POSTs to
   `/notify`; its HTTP style (dart:io, bearer header, error mapping) is the pattern for the
   new admin datasource.
4. Open `worker/README.md` — deploy/secret instructions you must keep accurate.

Do not write anything yet.

---

## Task A — Extract shared Firebase plumbing to `worker/src/firebase.js`

Move the functions listed above out of `index.js` into `worker/src/firebase.js` (export
each; keep the module-scope `certCache`/`saTokenCache` there). `index.js` imports them.
Zero behavior change — `/upload` and `/notify` byte-identical in behavior.

Extend `SA_SCOPES` with `https://www.googleapis.com/auth/identitytoolkit` (needed for
Auth admin calls in Session 6 — adding the scope now avoids re-touching token minting).

Add to `firebase.js` three write helpers (Firestore REST):

```js
/** POST …/documents/{collection}?documentId= — create with server-set name if id omitted. */
export async function firestoreCreateDoc(env, accessToken, collection, fields, id) { … }

/** PATCH …/documents/{path}?updateMask.fieldPaths=a&… — partial update. */
export async function firestorePatchFields(env, accessToken, path, fields) { … }

/** POST …/documents:commit — atomic multi-write (transforms + preconditions). */
export async function firestoreCommit(env, accessToken, writes) { … }
```

Each takes/returns PLAIN JS values and converts to/from Firestore typed values — add
`toFirestoreFields(obj)` / existing unwrap logic generalized (`fromFirestoreFields`,
extracted from `firestoreGetFields`; extend it to handle `timestampValue`, `arrayValue`,
`mapValue`, `nullValue`, `doubleValue` — the current 3-type unwrap is too narrow for
admin docs).

## Task B — `worker/src/admin.js`: router + permission middleware

```js
import { verifyFirebaseToken, getServiceAccountToken, firestoreGetFields,
         firestoreCreateDoc, json, bearer } from './firebase.js';

/**
 * Every /admin/* call: verify ID token → load /admins/{uid} → require isActive
 * and (perm ∈ permissions or '*'). Returns {uid, admin, accessToken} or a
 * Response (401/403) the route handler returns as-is.
 */
async function requireAdmin(request, env, cors, perm) { … }

export async function handleAdmin(request, env, cors) {
  const path = new URL(request.url).pathname;
  const routes = {
    '/admin/ping':  { perm: 'system.tools', fn: handlePing },
    '/admin/audit': { perm: null,           fn: handleClientAudit }, // any ACTIVE staff
  };
  const route = routes[path];
  if (!route) return json({ error: 'not_found' }, 404, cors);
  const auth = await requireAdmin(request, env, cors, route.perm);
  if (auth instanceof Response) return auth;
  return route.fn(request, env, cors, auth);
}
```

`requireAdmin` details: `perm === null` still requires an ACTIVE staff doc. On any check
failure return `json({error:'forbidden'},403,cors)` — never leak which check failed.

## Task C — Audit writer

In `admin.js`:

```js
/**
 * Immutable audit entry. Written ONLY here (client write is rules-denied).
 * `reported: true` marks client-reported entries (best-effort trust level);
 * Worker-performed ops write reported: false.
 */
export async function writeAudit(env, accessToken, {
  actorUid, action, targetType, targetId,
  before = null, after = null, reason = null, reported = false, ip = null,
}) {
  return firestoreCreateDoc(env, accessToken, 'auditLogs', {
    actorUid, action, targetType, targetId, before, after, reason, reported, ip,
    createdAt: new Date().toISOString(),
  });
}
```

`handlePing` — returns `{uid, role, permissions}` from the loaded admin doc (smoke-test
endpoint, also the health probe for Session 15).
`handleClientAudit` — validates body `{action, targetType, targetId, before?, after?,
reason?}` (strings, lengths ≤ 2000), stamps `actorUid` from the VERIFIED token (never from
body), `reported: true`, `ip` from `request.headers.get('cf-connecting-ip')`.

## Task D — Wire `/admin/` prefix in `index.js`

In the `fetch` handler, before the existing pathname checks:

```js
if (pathname.startsWith('/admin/')) return handleAdmin(request, env, cors);
```

(import `handleAdmin` from `./admin.js`).

## Task E — Flutter `AdminApiDataSource`

Create `lib/data/admin/datasources/admin_api_datasource.dart` copying the notify
datasource's HTTP style: `Future<Map<String, dynamic>> post(String path, Map body)` —
base `AppConfig.workerBaseUrl`, bearer = current user ID token, throws typed failures on
401/403/4xx/5xx, fail-fast when `!AppConfig.workerConfigured`. Add
`reportAudit(...)` fire-and-forget helper (swallows errors — same contract as `_notify*`).
Register in `injector.dart`.

---

## Smoke Test

- [ ] `cd worker && npx wrangler dev` with `.dev.vars` (PROJECT_ID + FIREBASE_SERVICE_ACCOUNT)
      starts clean; `/upload` + `/notify` behavior unchanged (existing manual checks).
- [ ] `curl -X POST localhost:8787/admin/ping` (no token) → 401.
- [ ] With a non-staff user's ID token → 403.
- [ ] With the founder's ID token (after Session 1 seed) → 200 `{role:'founder',…}`.
- [ ] `POST /admin/audit` as founder → doc appears in `/auditLogs` with `reported: true`,
      actorUid = founder uid.
- [ ] `flutter analyze` 0 · `flutter test` green (datasource unit test with a fake
      HttpClient if the notify datasource has one to copy) · parity script passes.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_03_CONSOLE_SHELL.md
User action: `wrangler deploy` when convenient (dev-tested is enough to continue).
```
