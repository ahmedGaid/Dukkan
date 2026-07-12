/**
 * Shared Firebase plumbing for the Dukkan Worker.
 *
 * Everything the Worker needs to (a) verify an incoming Firebase ID token,
 * (b) mint a service-account OAuth token, and (c) read/write Firestore via
 * the REST API lives here so both the public routes (`/upload`, `/notify` in
 * `index.js`) and the privileged admin routes (`/admin/*` in `admin.js`)
 * share ONE copy — no duplicated token/cert caching, no drift.
 *
 * Extracted verbatim from `index.js` (Session 2 / FILE_02); the only additions
 * are the write helpers (`firestoreCreateDoc`/`firestorePatchFields`/
 * `firestoreCommit`), the generalized typed-value conversion
 * (`toFirestoreFields`/`fromFirestoreFields`), and the extra OAuth scope for
 * the Auth admin API (used from Session 6 on).
 */
import { importPKCS8, importX509, jwtVerify, SignJWT } from 'jose';

// Firebase session tokens are signed by this Google service account. Its public
// keys are published only as X.509 certs here (there is no JWK endpoint for
// them) — `jose.importX509` turns each PEM into a verify key.
const GOOGLE_CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

// Scopes minted into the service-account token:
//   datastore          — Firestore REST reads/writes
//   firebase.messaging — FCM v1 sends
//   identitytoolkit    — Auth admin (disable/reset/lookup) from Session 6 on;
//                        added now so token minting is never re-touched later.
const SA_SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
  'https://www.googleapis.com/auth/identitytoolkit',
].join(' ');

// Module-scope caches: survive across requests on a warm isolate.
let certCache = { certs: null, expiresAt: 0 };
let saTokenCache = { token: null, expiresAt: 0 };

// ---------------------------------------------------------------------------
// Token verification
// ---------------------------------------------------------------------------

/** Reads the Bearer token off a request, or null when absent/malformed. */
export function bearer(request) {
  const m = (request.headers.get('authorization') ?? '').match(/^Bearer (.+)$/);
  return m ? m[1] : null;
}

export async function verifyFirebaseToken(token, projectId) {
  const kid = JSON.parse(b64urlDecode(token.split('.')[0])).kid;
  const pem = (await googleCerts())[kid];
  if (!pem) throw new Error('unknown_kid');
  const key = await importX509(pem, 'RS256');
  // jose checks the RS256 signature plus exp/iat/nbf; we pin issuer + audience.
  const { payload } = await jwtVerify(token, key, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  return payload;
}

async function googleCerts() {
  const now = Date.now();
  if (certCache.certs && now < certCache.expiresAt) return certCache.certs;
  const res = await fetch(GOOGLE_CERTS_URL);
  const certs = await res.json();
  const maxAge = parseMaxAge(res.headers.get('cache-control')) ?? 3600;
  certCache = { certs, expiresAt: now + maxAge * 1000 };
  return certs;
}

function parseMaxAge(cacheControl) {
  const m = (cacheControl ?? '').match(/max-age=(\d+)/);
  return m ? parseInt(m[1], 10) : null;
}

/**
 * Mints (and caches, module-scope, for its ~1h lifetime) an OAuth2 access
 * token for the service account via the JWT-bearer grant — this is the same
 * flow the Firebase Admin SDK uses under the hood, done by hand here since
 * Workers can't run the Node Admin SDK.
 */
export async function getServiceAccountToken(env) {
  const now = Date.now();
  if (saTokenCache.token && now < saTokenCache.expiresAt) return saTokenCache.token;

  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const key = await importPKCS8(sa.private_key, 'RS256');
  const iat = Math.floor(now / 1000);
  const jwt = await new SignJWT({ scope: SA_SCOPES })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(iat)
    .setExpirationTime(iat + 3600)
    .sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`token_exchange_${res.status}: ${await res.text()}`);
  const tok = await res.json();
  saTokenCache = { token: tok.access_token, expiresAt: now + (tok.expires_in - 60) * 1000 };
  return saTokenCache.token;
}

// ---------------------------------------------------------------------------
// Firestore typed-value conversion (plain JS  <->  Firestore REST `Value`s)
// ---------------------------------------------------------------------------

/** Unwraps one Firestore typed value to a plain JS value. */
function unwrapValue(v) {
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return Number(v.integerValue);
  if (v.doubleValue !== undefined) return Number(v.doubleValue);
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.timestampValue !== undefined) return v.timestampValue; // ISO string (app convention)
  if (v.nullValue !== undefined) return null;
  if (v.arrayValue !== undefined) return (v.arrayValue.values ?? []).map(unwrapValue);
  if (v.mapValue !== undefined) return fromFirestoreFields(v.mapValue.fields ?? {});
  // referenceValue / geoPointValue / bytesValue — unused by admin docs.
  return null;
}

/** Firestore `fields` map -> plain JS object. */
export function fromFirestoreFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields ?? {})) out[k] = unwrapValue(v);
  return out;
}

/** Wraps one plain JS value as a Firestore typed value. */
function toValue(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    // Money is integer piasters; keep whole numbers as integers.
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === 'object') return { mapValue: { fields: toFirestoreFields(v) } };
  return { nullValue: null };
}

/**
 * Plain JS object -> Firestore `fields` map. `undefined` keys are skipped
 * (not written); explicit `null` is written as a nullValue.
 */
export function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj ?? {})) {
    if (v === undefined) continue;
    fields[k] = toValue(v);
  }
  return fields;
}

// ---------------------------------------------------------------------------
// Firestore REST reads/writes (service-account authed, bypass security rules)
// ---------------------------------------------------------------------------

const FS_BASE = (env) =>
  `https://firestore.googleapis.com/v1/projects/${env.PROJECT_ID}/databases/(default)/documents`;

/** Reads one Firestore doc via REST and unwraps its typed fields to plain JS. */
export async function firestoreGetFields(env, accessToken, path) {
  const res = await fetch(`${FS_BASE(env)}/${path}`, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`firestore_get_${res.status}: ${await res.text()}`);
  const doc = await res.json();
  return fromFirestoreFields(doc.fields ?? {});
}

/**
 * POST …/documents/{collection}?documentId= — create a doc. When [id] is
 * omitted Firestore assigns a random name. Returns the created document.
 */
export async function firestoreCreateDoc(env, accessToken, collection, fields, id) {
  const base = `${FS_BASE(env)}/${collection}`;
  const url = id ? `${base}?documentId=${encodeURIComponent(id)}` : base;
  const res = await fetch(url, {
    method: 'POST',
    headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: JSON.stringify({ fields: toFirestoreFields(fields) }),
  });
  if (!res.ok) throw new Error(`firestore_create_${res.status}: ${await res.text()}`);
  return res.json();
}

/**
 * PATCH …/documents/{path}?updateMask.fieldPaths=a&… — partial update. Only
 * the keys present in [fields] are written; everything else on the doc is
 * left untouched. [path] is the full doc path, e.g. `admins/{uid}`.
 */
export async function firestorePatchFields(env, accessToken, path, fields) {
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  const res = await fetch(`${FS_BASE(env)}/${path}?${mask}`, {
    method: 'PATCH',
    headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: JSON.stringify({ fields: toFirestoreFields(fields) }),
  });
  if (!res.ok) throw new Error(`firestore_patch_${res.status}: ${await res.text()}`);
  return res.json();
}

/**
 * POST …/documents:commit — one atomic batch of writes (create/update/delete
 * with optional transforms + preconditions). [writes] is the raw Firestore
 * `Write[]` array; callers build it (via `toFirestoreFields` for `update`s).
 */
export async function firestoreCommit(env, accessToken, writes) {
  const res = await fetch(`${FS_BASE(env)}:commit`, {
    method: 'POST',
    headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
  if (!res.ok) throw new Error(`firestore_commit_${res.status}: ${await res.text()}`);
  return res.json();
}

// ---------------------------------------------------------------------------
// FCM
// ---------------------------------------------------------------------------

export async function sendFcm(env, accessToken, { token, title, body, data }) {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${env.PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
      body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
    },
  );
  if (!res.ok) throw new Error(`fcm_send_${res.status}: ${await res.text()}`);
}

// ---------------------------------------------------------------------------
// Small shared utilities
// ---------------------------------------------------------------------------

export function b64urlDecode(s) {
  return atob(s.replace(/-/g, '+').replace(/_/g, '/'));
}

export function json(body, status, extra) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...extra },
  });
}
