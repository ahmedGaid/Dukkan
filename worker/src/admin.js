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
  firestorePatchFields,
  firestoreDeleteDoc,
  firestoreCommit,
  identityToolkitCall,
  sendFcm,
  fsTimestamp,
  toValue,
  toFirestoreFields,
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

// ---------------------------------------------------------------------------
// Session 6 (FILE_06) — user management + staff (`/admins`) management.
// Every mutation here is Worker-routed (never a direct client Firestore/Auth
// write) so it can be permission-checked and audited in one place.
// ---------------------------------------------------------------------------

const PERSONA_ROLES = ['customer', 'owner', 'courier'];
const USER_STATUSES = ['active', 'suspended', 'banned'];
const STAFF_ROLE_RANK = { support: 40, moderator: 60, admin: 80, founder: 100 };

async function readBody(request) {
  try {
    return await request.json();
  } catch (_) {
    return null;
  }
}

/**
 * `/admin/users/set-disabled` — suspend/ban/reactivate a user account: flips
 * Firebase Auth `disableUser` (+ revokes existing sessions via `validSince`
 * so a suspended user's current token stops working immediately) and patches
 * `/users/{uid}.status`.
 */
async function handleSetDisabled(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid, status } = body ?? {};
  if (!isValidStr(uid, true) || !USER_STATUSES.includes(status)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `users/${uid}`);
  const disableUser = status !== 'active';
  try {
    await identityToolkitCall(env, accessToken, 'update', {
      localId: uid,
      disableUser,
      validSince: String(Math.floor(Date.now() / 1000)),
    });
    await firestorePatchFields(env, accessToken, `users/${uid}`, { status });
  } catch (e) {
    console.error('[admin] set-disabled failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }

  await writeAudit(env, accessToken, {
    actorUid,
    action: status === 'active' ? 'user.enable' : 'user.disable',
    targetType: 'user',
    targetId: uid,
    before: { status: before?.status ?? 'active' },
    after: { status },
  });
  return json({ ok: true }, 200, cors);
}

/**
 * `/admin/users/set-persona-role` — changes the app-facing persona
 * (customer/owner/courier) ONLY. Staff tiers live on `/admins` and are never
 * reachable through this endpoint.
 */
async function handleSetPersonaRole(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid, role } = body ?? {};
  if (!isValidStr(uid, true) || !PERSONA_ROLES.includes(role)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `users/${uid}`);
  await firestorePatchFields(env, accessToken, `users/${uid}`, { role });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'user.setRole',
    targetType: 'user',
    targetId: uid,
    before: { role: before?.role ?? null },
    after: { role },
  });
  return json({ ok: true }, 200, cors);
}

/** `/admin/users/change-email` — updates both the Auth account and the denormalized `/users` doc field. */
async function handleChangeEmail(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid, email } = body ?? {};
  if (!isValidStr(uid, true) || !isValidStr(email, true) || !email.includes('@')) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `users/${uid}`);
  try {
    await identityToolkitCall(env, accessToken, 'update', { localId: uid, email });
  } catch (e) {
    console.error('[admin] change-email failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }
  await firestorePatchFields(env, accessToken, `users/${uid}`, { email });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'user.changeEmail',
    targetType: 'user',
    targetId: uid,
    before: { email: before?.email ?? null },
    after: { email },
  });
  return json({ ok: true }, 200, cors);
}

/** `/admin/users/soft-delete` — reversible: flags the doc and disables sign-in, never deletes data. */
async function handleSoftDelete(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid } = body ?? {};
  if (!isValidStr(uid, true)) return json({ error: 'bad_request' }, 400, cors);

  try {
    await identityToolkitCall(env, accessToken, 'update', { localId: uid, disableUser: true });
  } catch (e) {
    console.error('[admin] soft-delete auth op failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }
  await firestorePatchFields(env, accessToken, `users/${uid}`, {
    deleted: true,
    deletedAt: fsTimestamp(new Date().toISOString()),
    deletedBy: actorUid,
  });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'user.softDelete',
    targetType: 'user',
    targetId: uid,
    before: { deleted: false },
    after: { deleted: true },
  });
  return json({ ok: true }, 200, cors);
}

/** `/admin/users/restore` — undoes `soft-delete`. */
async function handleRestore(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid } = body ?? {};
  if (!isValidStr(uid, true)) return json({ error: 'bad_request' }, 400, cors);

  try {
    await identityToolkitCall(env, accessToken, 'update', { localId: uid, disableUser: false });
  } catch (e) {
    console.error('[admin] restore auth op failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }
  await firestorePatchFields(env, accessToken, `users/${uid}`, {
    deleted: false,
    deletedAt: null,
    deletedBy: null,
  });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'user.restore',
    targetType: 'user',
    targetId: uid,
    before: { deleted: true },
    after: { deleted: false },
  });
  return json({ ok: true }, 200, cors);
}

/** `/admin/users/create` — staff-initiated account creation (email+password), same persona whitelist as signup. */
async function handleCreateUser(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { name, email, password, role } = body ?? {};
  if (
    !isValidStr(name, true) ||
    !isValidStr(email, true) ||
    !isValidStr(password, true) ||
    password.length < 6 ||
    !PERSONA_ROLES.includes(role)
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  let localId;
  try {
    const signUp = await identityToolkitCall(env, accessToken, 'signUp', { email, password });
    localId = signUp.localId;
  } catch (e) {
    console.error('[admin] create-user signUp failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }

  await firestoreCreateDoc(
    env,
    accessToken,
    'users',
    { name, email, role, createdAt: fsTimestamp(new Date().toISOString()) },
    localId,
  );
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'user.create',
    targetType: 'user',
    targetId: localId,
    before: null,
    after: { name, email, role },
  });
  return json({ ok: true, uid: localId }, 200, cors);
}

/**
 * `/admin/users/lookup` — Auth-side facts the `/users` doc doesn't carry
 * (verified/disabled flags, login history) for the user detail page.
 */
async function handleLookup(request, env, cors, auth) {
  const { accessToken } = auth;
  const body = await readBody(request);
  const { uid } = body ?? {};
  if (!isValidStr(uid, true)) return json({ error: 'bad_request' }, 400, cors);

  let result;
  try {
    result = await identityToolkitCall(env, accessToken, 'lookup', { localId: [uid] });
  } catch (e) {
    console.error('[admin] lookup failed', e);
    return json({ error: 'auth_op_failed' }, 502, cors);
  }
  const record = (result.users ?? [])[0];
  if (!record) return json({ error: 'not_found' }, 404, cors);

  return json(
    {
      email: record.email ?? null,
      emailVerified: record.emailVerified ?? false,
      disabled: record.disabled ?? false,
      lastLoginAt: record.lastLoginAt ?? null, // epoch ms string, Identity Toolkit convention
      createdAt: record.createdAt ?? null, // epoch ms string
    },
    200,
    cors,
  );
}

/**
 * `/admin/admins/set` — creates or updates a staff member's `/admins/{uid}`
 * doc: reads the role's permission set from `/roles/{role}`, denormalizes
 * `permissions = role.permissions ∪ extraPermissions`, and stamps `rank` from
 * the role. Rank-guarded: the caller must outrank BOTH the target's current
 * rank and the rank they are being promoted/demoted to — this is what stops
 * an admin from touching (or ever creating another) founder.
 */
async function handleAdminsSet(request, env, cors, auth) {
  const { uid: actorUid, admin: callerAdmin, accessToken } = auth;
  const body = await readBody(request);
  const { uid, role, extraPermissions } = body ?? {};
  const extras = Array.isArray(extraPermissions) ? extraPermissions : [];
  if (
    !isValidStr(uid, true) ||
    !Object.prototype.hasOwnProperty.call(STAFF_ROLE_RANK, role) ||
    !extras.every((p) => typeof p === 'string')
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const roleDoc = await firestoreGetFields(env, accessToken, `roles/${role}`);
  if (!roleDoc) return json({ error: 'unknown_role' }, 400, cors);
  const newRank = Number(roleDoc.rank ?? STAFF_ROLE_RANK[role]);

  const before = await firestoreGetFields(env, accessToken, `admins/${uid}`);
  const currentRank = Number(before?.rank ?? 0);
  const callerRank = Number(callerAdmin.rank ?? 0);
  if (callerRank <= currentRank || callerRank <= newRank) {
    return json({ error: 'forbidden' }, 403, cors);
  }

  const rolePerms = Array.isArray(roleDoc.permissions) ? roleDoc.permissions : [];
  const permissions = [...new Set([...rolePerms, ...extras])];
  const after = { role, permissions, isActive: true, rank: newRank };

  await firestorePatchFields(env, accessToken, `admins/${uid}`, after);
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'admin.set',
    targetType: 'admin',
    targetId: uid,
    before,
    after,
  });
  return json({ ok: true }, 200, cors);
}

/** `/admin/admins/remove` — revokes staff status (same rank guard as `admins/set`). */
async function handleAdminsRemove(request, env, cors, auth) {
  const { uid: actorUid, admin: callerAdmin, accessToken } = auth;
  const body = await readBody(request);
  const { uid } = body ?? {};
  if (!isValidStr(uid, true)) return json({ error: 'bad_request' }, 400, cors);

  const before = await firestoreGetFields(env, accessToken, `admins/${uid}`);
  if (!before) return json({ ok: true }, 200, cors); // already gone — idempotent

  const currentRank = Number(before.rank ?? 0);
  const callerRank = Number(callerAdmin.rank ?? 0);
  if (callerRank <= currentRank) return json({ error: 'forbidden' }, 403, cors);

  await firestoreDeleteDoc(env, accessToken, `admins/${uid}`);
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'admin.remove',
    targetType: 'admin',
    targetId: uid,
    before,
    after: null,
  });
  return json({ ok: true }, 200, cors);
}

// ---------------------------------------------------------------------------
// Session 7 (FILE_07) — shop ownership transfer. Every other shop mutation
// (status/feature/verify/edit/soft-delete) is Firestore-direct under the
// `shops.update` rules branch; only an `ownerUid` change is Worker-routed —
// the rules explicitly forbid a client from ever touching that field.
// ---------------------------------------------------------------------------

/**
 * `/admin/shops/transfer` — reassigns a shop to a different owner. The new
 * owner must already have a `/users` doc with `role: 'owner'` (else 400); the
 * old owner's persona role is left untouched (a founder/admin handles that
 * manually via user management, Session 6 — noted in the response so the
 * console can show a hint).
 */
async function handleShopsTransfer(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { shopId, newOwnerUid } = body ?? {};
  if (!isValidStr(shopId, true) || !isValidStr(newOwnerUid, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const newOwner = await firestoreGetFields(env, accessToken, `users/${newOwnerUid}`);
  if (!newOwner || newOwner.role !== 'owner') {
    return json({ error: 'invalid_new_owner' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `shops/${shopId}`);
  if (!before) return json({ error: 'not_found' }, 404, cors);
  const oldOwnerUid = before.ownerUid ?? null;

  await firestorePatchFields(env, accessToken, `shops/${shopId}`, { ownerUid: newOwnerUid });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'shop.transfer',
    targetType: 'shop',
    targetId: shopId,
    before: { ownerUid: oldOwnerUid },
    after: { ownerUid: newOwnerUid },
  });

  let oldOwnerStillOwnerRole = false;
  if (oldOwnerUid) {
    const oldOwner = await firestoreGetFields(env, accessToken, `users/${oldOwnerUid}`);
    oldOwnerStillOwnerRole = oldOwner?.role === 'owner';
  }

  return json({ ok: true, oldOwnerUid, oldOwnerStillOwnerRole }, 200, cors);
}

// ---------------------------------------------------------------------------
// Session 10 (FILE_10) — order admin: force-status, reassign-driver, cancel.
// The client-side transition whitelist in `firestore.rules` stays untouched;
// these three are the ONLY way an order is corrected outside it, always
// audited, always with a caller-supplied reason.
// ---------------------------------------------------------------------------

const ORDER_STATUSES = [
  'pending', 'accepted', 'preparing', 'outForDelivery', 'delivered', 'cancelled', 'rejected',
];
const TERMINAL_STATUSES = ['delivered', 'cancelled', 'rejected'];

const docName = (env, path) =>
  `projects/${env.PROJECT_ID}/databases/(default)/documents/${path}`;

/** One `update` Write — only [mask] fields are touched, mirrors `firestorePatchFields`. */
function updateWrite(env, path, fields, mask) {
  return {
    update: { name: docName(env, path), fields: toFirestoreFields(fields) },
    updateMask: { fieldPaths: mask },
  };
}

/** One `transform` Write — appends [values] to the array at [fieldPath]. */
function appendArrayWrite(env, path, fieldPath, values) {
  return {
    transform: {
      document: docName(env, path),
      fieldTransforms: [
        { fieldPath, appendMissingElements: { values: values.map(toValue) } },
      ],
    },
  };
}

/**
 * Decrements one driver's `activeOrdersCount` (floor 0) — the same side
 * effect `_advanceStatus` (client) applies inline, done here as an extra
 * commit write since the Worker's reads aren't inside the commit itself.
 */
async function buildDriverDecrementWrite(env, accessToken, driverUid) {
  const driver = await firestoreGetFields(env, accessToken, `drivers/${driverUid}`);
  const active = Number(driver?.activeOrdersCount ?? 0);
  return updateWrite(env, `drivers/${driverUid}`, {
    activeOrdersCount: active > 0 ? active - 1 : 0,
  }, ['activeOrdersCount']);
}

/**
 * `/admin/orders/force-status` — moves an order to any of the 7 statuses
 * outside the normal whitelist. `commissionPayable` is always explicitly set
 * (true iff landing on `delivered`) since, unlike the client's one-directional
 * `_advanceStatus`, this can move an order backward out of `delivered` too.
 * The driver's slot is only freed on the transition INTO a terminal status
 * from a non-terminal one — so forcing an already-delivered order back to
 * `preparing` then forward to `delivered` again decrements exactly once, not
 * twice (see the FILE_10 smoke test).
 */
async function handleForceStatus(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { orderId, toStatus, reason } = body ?? {};
  if (!isValidStr(orderId, true) || !ORDER_STATUSES.includes(toStatus) || !isValidStr(reason, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `orders/${orderId}`);
  if (!before) return json({ error: 'not_found' }, 404, cors);

  const nowIso = new Date().toISOString();
  const writes = [
    updateWrite(env, `orders/${orderId}`, {
      status: toStatus,
      commissionPayable: toStatus === 'delivered',
    }, ['status', 'commissionPayable']),
    appendArrayWrite(env, `orders/${orderId}`, 'statusHistory', [
      { status: toStatus, at: nowIso, byUid: actorUid, forced: true },
    ]),
  ];

  const enteringTerminal =
    TERMINAL_STATUSES.includes(toStatus) && !TERMINAL_STATUSES.includes(before.status);
  if (enteringTerminal && before.driverUid) {
    writes.push(await buildDriverDecrementWrite(env, accessToken, before.driverUid));
  }

  await firestoreCommit(env, accessToken, writes);
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'order.forceStatus',
    targetType: 'order',
    targetId: orderId,
    before: { status: before.status },
    after: { status: toStatus },
    reason,
  });
  return json({ ok: true }, 200, cors);
}

/**
 * `/admin/orders/reassign-driver` — moves the order's assigned driver, or
 * clears it (`clear: true`). Validates the new driver the same way the M9
 * client transaction does (online, not suspended, capacity, covers the
 * order's area) — the Worker bypasses rules, so this IS the enforcement.
 */
async function handleReassignDriver(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { orderId, newDriverUid, clear, reason } = body ?? {};
  if (!isValidStr(orderId, true) || !isValidStr(reason, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }
  if (!clear && !isValidStr(newDriverUid, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const order = await firestoreGetFields(env, accessToken, `orders/${orderId}`);
  if (!order) return json({ error: 'not_found' }, 404, cors);
  const oldDriverUid = order.driverUid ?? null;
  if (!clear && newDriverUid === oldDriverUid) {
    return json({ error: 'same_driver' }, 400, cors);
  }

  const writes = [];
  if (oldDriverUid) {
    writes.push(await buildDriverDecrementWrite(env, accessToken, oldDriverUid));
  }

  if (clear) {
    writes.push(updateWrite(env, `orders/${orderId}`, {
      driverUid: null, driverName: null, driverPhone: null, assignedAt: null,
    }, ['driverUid', 'driverName', 'driverPhone', 'assignedAt']));
  } else {
    const newDriver = await firestoreGetFields(env, accessToken, `drivers/${newDriverUid}`);
    if (!newDriver) return json({ error: 'driver_not_found' }, 400, cors);
    if (newDriver.isSuspended === true) return json({ error: 'driver_suspended' }, 400, cors);
    if (newDriver.isOnline !== true) return json({ error: 'driver_offline' }, 400, cors);
    const active = Number(newDriver.activeOrdersCount ?? 0);
    const max = Number(newDriver.maxActiveOrders ?? 0);
    if (active >= max) return json({ error: 'driver_capacity' }, 400, cors);
    const areas = Array.isArray(newDriver.areaIds) ? newDriver.areaIds : [];
    const orderArea = order.deliveryAddress?.areaId ?? null;
    if (!orderArea || !areas.includes(orderArea)) return json({ error: 'driver_area' }, 400, cors);

    writes.push(updateWrite(env, `drivers/${newDriverUid}`, {
      activeOrdersCount: active + 1,
    }, ['activeOrdersCount']));
    writes.push(updateWrite(env, `orders/${orderId}`, {
      driverUid: newDriverUid,
      driverName: newDriver.name ?? null,
      driverPhone: newDriver.phone ?? null,
      assignedAt: new Date().toISOString(), // plain ISO string — OrderModel parses it as one, not a Timestamp
    }, ['driverUid', 'driverName', 'driverPhone', 'assignedAt']));
  }

  await firestoreCommit(env, accessToken, writes);
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'order.reassign',
    targetType: 'order',
    targetId: orderId,
    before: { driverUid: oldDriverUid },
    after: { driverUid: clear ? null : newDriverUid },
    reason,
  });
  return json({ ok: true }, 200, cors);
}

/**
 * `/admin/orders/cancel` — cancels an order outside the customer's own
 * pending/accepted-only window. [refundNoteMinor] is a COD ledger note only;
 * no money actually moves (there is nothing to reverse — the customer never
 * paid electronically).
 */
async function handleCancelOrder(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { orderId, reason, refundNoteMinor } = body ?? {};
  if (!isValidStr(orderId, true) || !isValidStr(reason, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }
  if (refundNoteMinor != null && (!Number.isInteger(refundNoteMinor) || refundNoteMinor < 0)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const before = await firestoreGetFields(env, accessToken, `orders/${orderId}`);
  if (!before) return json({ error: 'not_found' }, 404, cors);
  if (TERMINAL_STATUSES.includes(before.status)) {
    return json({ error: 'already_terminal' }, 400, cors);
  }

  const nowIso = new Date().toISOString();
  const orderFields = { status: 'cancelled' };
  const orderMask = ['status'];
  if (refundNoteMinor != null) {
    orderFields.refundNoteMinor = refundNoteMinor;
    orderMask.push('refundNoteMinor');
  }

  const writes = [
    updateWrite(env, `orders/${orderId}`, orderFields, orderMask),
    appendArrayWrite(env, `orders/${orderId}`, 'statusHistory', [
      { status: 'cancelled', at: nowIso, byUid: actorUid, forced: true },
    ]),
  ];
  if (before.driverUid) {
    writes.push(await buildDriverDecrementWrite(env, accessToken, before.driverUid));
  }

  await firestoreCommit(env, accessToken, writes);
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'order.cancel',
    targetType: 'order',
    targetId: orderId,
    before: { status: before.status },
    after: { status: 'cancelled' },
    reason,
  });
  return json({ ok: true }, 200, cors);
}

// ---------------------------------------------------------------------------
// Session 13 (FILE_13) — notification center: broadcast (topic) + direct
// (token) push. Both write an immutable `/notifications` history doc so the
// console can show sent/failed/skipped status without re-deriving it from
// FCM, which gives no audience-size feedback on a topic send at all.
// ---------------------------------------------------------------------------

const AUDIENCE_TOPICS = {
  customers: ['role-customer'],
  owners: ['role-owner'],
  couriers: ['role-courier'],
  all: ['role-customer', 'role-owner', 'role-courier'],
};

async function writeNotificationHistory(env, accessToken, fields) {
  return firestoreCreateDoc(env, accessToken, 'notifications', {
    ...fields,
    sentAt: fsTimestamp(new Date().toISOString()),
  });
}

/**
 * `/admin/notify/broadcast` — sends to one or all three role topics (`all`
 * fans out sequentially, stopping at the first failure). `status` only
 * reflects whether the FCM send call(s) themselves succeeded — a topic send
 * has no delivery/recipient-count feedback, which is why the console's
 * confirm dialog says the audience size is unknown.
 */
async function handleNotifyBroadcast(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { audience, title, body: msgBody } = body ?? {};
  if (
    !Object.prototype.hasOwnProperty.call(AUDIENCE_TOPICS, audience) ||
    !isValidStr(title, true) ||
    !isValidStr(msgBody, true)
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  let status = 'sent';
  let error = null;
  for (const topic of AUDIENCE_TOPICS[audience]) {
    try {
      await sendFcm(env, accessToken, { topic, title, body: msgBody });
    } catch (e) {
      console.error('[admin] broadcast send failed', topic, e);
      status = 'failed';
      error = String(e);
      break;
    }
  }

  await writeNotificationHistory(env, accessToken, {
    kind: 'broadcast', audience, title, body: msgBody, sentBy: actorUid, status, error,
  });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'notify.broadcast',
    targetType: 'notification',
    targetId: audience,
    after: { audience, title },
  });
  return json({ ok: true, status }, 200, cors);
}

/**
 * `/admin/notify/user` — sends to one user's saved FCM token. No token on
 * file is `skipped`, not an error (the console's history/resend flow treats
 * it distinctly from `failed`).
 */
async function handleNotifyUser(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { uid, title, body: msgBody } = body ?? {};
  if (!isValidStr(uid, true) || !isValidStr(title, true) || !isValidStr(msgBody, true)) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  const target = await firestoreGetFields(env, accessToken, `users/${uid}`);
  const fcmToken = target?.fcmToken;

  let status;
  let error = null;
  if (!fcmToken) {
    status = 'skipped';
  } else {
    try {
      await sendFcm(env, accessToken, { token: fcmToken, title, body: msgBody });
      status = 'sent';
    } catch (e) {
      console.error('[admin] direct send failed', e);
      status = 'failed';
      error = String(e);
    }
  }

  await writeNotificationHistory(env, accessToken, {
    kind: 'direct', targetUid: uid, title, body: msgBody, sentBy: actorUid, status, error,
  });
  await writeAudit(env, accessToken, {
    actorUid,
    action: 'notify.direct',
    targetType: 'notification',
    targetId: uid,
    after: { title },
  });
  return json({ ok: true, status }, 200, cors);
}

// ---------------------------------------------------------------------------
// Session 14 (FILE_14) — media library: browse/stats/delete R2 objects. Read
// (`list`/`stats`) rides `images.delete` — media is one console area with no
// separate read permission, same one-perm-per-section shape as taxonomy/geo.
// ---------------------------------------------------------------------------

const MEDIA_LIST_LIMIT = 100;
const MEDIA_STATS_CAP = 10000; // bucket is small; an honest cap, not a real ceiling
const MEDIA_DELETE_MAX = 100;

/** `/admin/media/list` — one page of R2 objects, optionally prefix-filtered. */
async function handleMediaList(request, env, cors, _auth) {
  const body = await readBody(request);
  const { prefix, cursor } = body ?? {};
  if (
    (prefix != null && typeof prefix !== 'string') ||
    (cursor != null && typeof cursor !== 'string')
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  let listed;
  try {
    listed = await env.BUCKET.list({
      prefix: prefix || undefined,
      cursor: cursor || undefined,
      limit: MEDIA_LIST_LIMIT,
    });
  } catch (e) {
    console.error('[admin] media list failed', e);
    return json({ error: 'list_failed' }, 502, cors);
  }

  const objects = listed.objects.map((o) => ({ key: o.key, size: o.size, uploaded: o.uploaded }));
  return json({ objects, cursor: listed.truncated ? listed.cursor : null }, 200, cors);
}

/**
 * `/admin/media/stats` — full-bucket pagination loop (server-side, so the
 * console makes one call, not N). Capped at [MEDIA_STATS_CAP] objects.
 */
async function handleMediaStats(request, env, cors, _auth) {
  let count = 0;
  let totalBytes = 0;
  const byFolder = {};
  let cursor;
  let truncated = false;

  try {
    do {
      const listed = await env.BUCKET.list({ cursor, limit: MEDIA_LIST_LIMIT });
      for (const o of listed.objects) {
        count += 1;
        totalBytes += o.size;
        const folder = o.key.split('/')[0] || 'unknown';
        const bucket = byFolder[folder] ?? (byFolder[folder] = { count: 0, bytes: 0 });
        bucket.count += 1;
        bucket.bytes += o.size;
      }
      cursor = listed.truncated ? listed.cursor : undefined;
      if (count >= MEDIA_STATS_CAP) {
        truncated = true;
        break;
      }
    } while (cursor);
  } catch (e) {
    console.error('[admin] media stats failed', e);
    return json({ error: 'stats_failed' }, 502, cors);
  }

  return json({ count, totalBytes, byFolder, truncated }, 200, cors);
}

/** `/admin/media/delete` — permanent, unrecoverable R2 delete + one audit entry. */
async function handleMediaDelete(request, env, cors, auth) {
  const { uid: actorUid, accessToken } = auth;
  const body = await readBody(request);
  const { keys } = body ?? {};
  if (
    !Array.isArray(keys) ||
    keys.length === 0 ||
    keys.length > MEDIA_DELETE_MAX ||
    !keys.every((k) => typeof k === 'string' && k.length > 0 && k.length <= MAX_STR)
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  try {
    await env.BUCKET.delete(keys);
  } catch (e) {
    console.error('[admin] media delete failed', e);
    return json({ error: 'delete_failed' }, 502, cors);
  }

  await writeAudit(env, accessToken, {
    actorUid,
    action: 'media.delete',
    targetType: 'media',
    targetId: keys[0],
    after: { count: keys.length, keys: keys.slice(0, 20) },
  });
  return json({ ok: true, count: keys.length }, 200, cors);
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
    '/admin/users/set-disabled': { perm: 'users.update', fn: handleSetDisabled },
    '/admin/users/set-persona-role': { perm: 'users.update', fn: handleSetPersonaRole },
    '/admin/users/change-email': { perm: 'users.update', fn: handleChangeEmail },
    '/admin/users/soft-delete': { perm: 'users.delete', fn: handleSoftDelete },
    '/admin/users/restore': { perm: 'users.delete', fn: handleRestore },
    '/admin/users/create': { perm: 'users.create', fn: handleCreateUser },
    '/admin/users/lookup': { perm: 'users.read', fn: handleLookup },
    '/admin/admins/set': { perm: 'admins.manage', fn: handleAdminsSet },
    '/admin/admins/remove': { perm: 'admins.manage', fn: handleAdminsRemove },
    '/admin/shops/transfer': { perm: 'shops.transfer', fn: handleShopsTransfer },
    '/admin/orders/force-status': { perm: 'orders.forceStatus', fn: handleForceStatus },
    '/admin/orders/reassign-driver': { perm: 'orders.assignDriver', fn: handleReassignDriver },
    '/admin/orders/cancel': { perm: 'orders.cancel', fn: handleCancelOrder },
    '/admin/notify/broadcast': { perm: 'notifications.send', fn: handleNotifyBroadcast },
    '/admin/notify/user': { perm: 'notifications.send', fn: handleNotifyUser },
    '/admin/media/list': { perm: 'images.delete', fn: handleMediaList },
    '/admin/media/stats': { perm: 'images.delete', fn: handleMediaStats },
    '/admin/media/delete': { perm: 'images.delete', fn: handleMediaDelete },
  };
  const route = routes[path];
  if (!route) return json({ error: 'not_found' }, 404, cors);

  const auth = await requireAdmin(request, env, cors, route.perm);
  if (auth instanceof Response) return auth;
  return route.fn(request, env, cors, auth);
}
