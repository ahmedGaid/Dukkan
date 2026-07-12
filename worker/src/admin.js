/**
 * Dukkan Worker — privileged Back-Office API (`/admin/*`).
 *
 * Every admin operation is Worker-routed so it can be (a) permission-checked
 * server-side against the caller's `/admins/{uid}` doc and (b) written to the
 * immutable `/auditLogs` collection that clients cannot write. This is the
 * server half of the Founder Console's defense-in-depth (UI hide + Firestore
 * `hasPerm` rule + this middleware) — the UI is NEVER the only gate.
 *
 * Session 2 (FILE_02) ships the skeleton: the permission middleware, the audit
 * writer, and two endpoints — `/admin/ping` (smoke test + health probe) and
 * `/admin/audit` (best-effort reporting for client-direct, rules-guarded
 * mutations). Later sessions add real management endpoints to the `routes`
 * table below.
 */
import {
  verifyFirebaseToken,
  getServiceAccountToken,
  firestoreGetFields,
  firestoreCreateDoc,
  json,
  bearer,
} from './firebase.js';

/**
 * Gate for every `/admin/*` call: verify the ID token, load the caller's
 * `/admins/{uid}` doc, require it to be ACTIVE, and (unless [perm] is null)
 * require [perm] — or the `'*'` wildcard — to be in its `permissions`.
 *
 * Fails CLOSED: a missing doc, `isActive !== true`, or a missing permission
 * all return an identical `403 forbidden` — never leaking which check failed.
 * Returns `{ uid, admin, accessToken }` on success, or a `Response` the route
 * handler must return as-is.
 */
async function requireAdmin(request, env, cors, perm) {
  const token = bearer(request);
  if (!token) return json({ error: 'missing_token' }, 401, cors);

  let uid;
  try {
    const payload = await verifyFirebaseToken(token, env.PROJECT_ID);
    uid = payload.sub;
    if (!uid) throw new Error('no sub');
  } catch (_) {
    return json({ error: 'invalid_token' }, 401, cors);
  }

  let accessToken;
  try {
    accessToken = await getServiceAccountToken(env);
  } catch (e) {
    console.error('[admin] service account token failed', e);
    return json({ error: 'server_misconfigured' }, 500, cors);
  }

  const admin = await firestoreGetFields(env, accessToken, `admins/${uid}`);
  if (!admin || admin.isActive !== true) return json({ error: 'forbidden' }, 403, cors);

  if (perm !== null) {
    const perms = Array.isArray(admin.permissions) ? admin.permissions : [];
    if (!perms.includes(perm) && !perms.includes('*')) {
      return json({ error: 'forbidden' }, 403, cors);
    }
  }
  return { uid, admin, accessToken };
}

/**
 * Immutable audit entry. Written ONLY here (client write is rules-denied).
 * `reported: true` marks client-reported entries (best-effort trust level);
 * Worker-performed ops write `reported: false`.
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

/**
 * `/admin/ping` — echoes the loaded admin doc's identity. Doubles as the
 * Session-15 health probe. Requires `system.tools` (founder's `'*'` covers it).
 */
async function handlePing(request, env, cors, auth) {
  const { uid, admin } = auth;
  return json(
    {
      uid,
      role: admin.role ?? null,
      permissions: Array.isArray(admin.permissions) ? admin.permissions : [],
    },
    200,
    cors,
  );
}

const MAX_STR = 2000;
const isValidStr = (s, required) =>
  s == null ? !required : typeof s === 'string' && s.length > 0 && s.length <= MAX_STR;
// before/after may be a snapshot object or string — cap its serialized size
// and drop it (to null) rather than reject when it is oversized.
const capSnapshot = (v) =>
  v == null ? null : JSON.stringify(v).length <= MAX_STR ? v : null;

/**
 * `/admin/audit` — any ACTIVE staff member reports a client-direct mutation.
 * The actor is taken from the VERIFIED token, never the body, so a caller
 * cannot forge who did what. Best-effort by nature (the mutation itself is
 * rules-guarded, not Worker-routed), so this is the honest `reported: true`
 * trust level.
 */
async function handleClientAudit(request, env, cors, auth) {
  const { uid, accessToken } = auth;

  let body;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: 'bad_json' }, 400, cors);
  }
  const { action, targetType, targetId, before, after, reason } = body ?? {};
  if (
    !isValidStr(action, true) ||
    !isValidStr(targetType, true) ||
    !isValidStr(targetId, true) ||
    !isValidStr(reason, false)
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  try {
    await writeAudit(env, accessToken, {
      actorUid: uid, // from the verified token, NOT the body
      action,
      targetType,
      targetId,
      before: capSnapshot(before),
      after: capSnapshot(after),
      reason: reason ?? null,
      reported: true,
      ip: request.headers.get('cf-connecting-ip'),
    });
  } catch (e) {
    console.error('[admin] audit write failed', e);
    return json({ error: 'audit_failed' }, 500, cors);
  }
  return json({ ok: true }, 200, cors);
}

/**
 * Dispatch table for `/admin/*`. `perm: null` still requires an ACTIVE staff
 * doc (any staff), a string requires that permission (or `'*'`). Later
 * sessions add rows here — the middleware and audit writer stay untouched.
 */
export async function handleAdmin(request, env, cors) {
  const path = new URL(request.url).pathname;
  const routes = {
    '/admin/ping': { perm: 'system.tools', fn: handlePing },
    '/admin/audit': { perm: null, fn: handleClientAudit }, // any ACTIVE staff
  };
  const route = routes[path];
  if (!route) return json({ error: 'not_found' }, 404, cors);

  const auth = await requireAdmin(request, env, cors, route.perm);
  if (auth instanceof Response) return auth;
  return route.fn(request, env, cors, auth);
}
