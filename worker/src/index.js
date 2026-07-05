/**
 * Dukkan Worker — image uploads (R2) + order push notifications (FCM v1).
 *
 * The Flutter app cannot hold R2 credentials or an FCM service account (an
 * APK is unpackable, so any embedded secret is effectively public). This
 * Worker is the trusted middle-man for both:
 *
 *   POST /upload  — app --(bytes + Bearer <Firebase ID token>)--> Worker
 *                   Worker verifies token -> env.BUCKET.put(key, bytes)
 *                   -> returns { url }
 *
 *   POST /notify  — app --(orderId/type/title/body + Bearer ID token)--> Worker
 *                   Worker verifies token, reads the order+shop from Firestore
 *                   (service account, bypasses security rules by design —
 *                   this is the trusted backend), checks the caller is a real
 *                   party to that order, resolves the *other* party's saved
 *                   FCM token, and sends via FCM HTTP v1.
 *                   -> returns { ok: true } (or a no-op if the recipient has
 *                   no token yet — not an error, just nothing to deliver to)
 *
 * Bindings (see wrangler.toml + `wrangler secret put`):
 *   BUCKET                    R2 bucket that stores uploaded images
 *   PROJECT_ID                Firebase project id (dukkan-93042)
 *   PUBLIC_BASE_URL           public-read origin for the bucket
 *   ALLOWED_ORIGIN            CORS origin for the app
 *   FIREBASE_SERVICE_ACCOUNT  secret — the Firebase service-account JSON key
 *                             (Firebase console -> Project settings ->
 *                             Service accounts -> Generate new private key).
 *                             Used to mint an OAuth2 access token for both
 *                             the Firestore REST API (order/shop/user reads)
 *                             and the FCM v1 send endpoint.
 */
import { importPKCS8, importX509, jwtVerify, SignJWT } from 'jose';

// Firebase session tokens are signed by this Google service account. Its public
// keys are published only as X.509 certs here (there is no JWK endpoint for
// them) — `jose.importX509` turns each PEM into a verify key.
const GOOGLE_CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB — a logo / product photo, not a video
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_FOLDERS = new Set(['shop-logos', 'product-images']);
const NOTIFY_TYPES = new Set(['newOrder', 'statusUpdate']);
const SA_SCOPES =
  'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging';

// Module-scope caches: survive across requests on a warm isolate.
let certCache = { certs: null, expiresAt: 0 };
let saTokenCache = { token: null, expiresAt: 0 };

export default {
  async fetch(request, env) {
    const cors = corsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    if (request.method !== 'POST') {
      return json({ error: 'method_not_allowed' }, 405, cors);
    }

    const pathname = new URL(request.url).pathname;
    if (pathname === '/notify') return handleNotify(request, env, cors);
    return handleUpload(request, env, cors);
  },
};

async function handleUpload(request, env, cors) {
  // 1. Auth — the caller must be a real signed-in Dukkan user.
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

  // 2. Validate the upload before touching storage.
  const folder = new URL(request.url).searchParams.get('folder') ?? '';
  if (!ALLOWED_FOLDERS.has(folder)) {
    return json({ error: 'bad_folder' }, 400, cors);
  }
  const contentType = request.headers.get('content-type') ?? '';
  if (!ALLOWED_TYPES.has(contentType)) {
    return json({ error: 'bad_content_type' }, 415, cors);
  }
  const bytes = await request.arrayBuffer();
  if (bytes.byteLength === 0) return json({ error: 'empty' }, 400, cors);
  if (bytes.byteLength > MAX_BYTES) return json({ error: 'too_large' }, 413, cors);

  // 3. Store. Key namespaced by uid so one user can't overwrite another's path.
  const ext = contentType.split('/')[1];
  const key = `${folder}/${uid}/${crypto.randomUUID()}.${ext}`;
  await env.BUCKET.put(key, bytes, { httpMetadata: { contentType } });

  const publicUrl = `${env.PUBLIC_BASE_URL.replace(/\/$/, '')}/${key}`;
  return json({ url: publicUrl }, 200, cors);
}

/**
 * Authorization model: the caller must be one of the two real parties to the
 * order, and can only notify the *other* one — never an arbitrary uid.
 *   newOrder     — caller must be the order's customer; target = shop owner.
 *   statusUpdate — caller must be the shop's owner;    target = customer.
 * Title/body come from the app (already bilingual, built from its own i18n
 * strings) — the Worker only decides *whether* to send and *to whom*.
 */
async function handleNotify(request, env, cors) {
  const token = bearer(request);
  if (!token) return json({ error: 'missing_token' }, 401, cors);
  let callerUid;
  try {
    const payload = await verifyFirebaseToken(token, env.PROJECT_ID);
    callerUid = payload.sub;
    if (!callerUid) throw new Error('no sub');
  } catch (_) {
    return json({ error: 'invalid_token' }, 401, cors);
  }

  let body;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: 'bad_json' }, 400, cors);
  }
  const { orderId, type, title, body: msgBody } = body ?? {};
  if (
    typeof orderId !== 'string' || !orderId ||
    !NOTIFY_TYPES.has(type) ||
    typeof title !== 'string' || !title ||
    typeof msgBody !== 'string' || !msgBody
  ) {
    return json({ error: 'bad_request' }, 400, cors);
  }

  let accessToken;
  try {
    accessToken = await getServiceAccountToken(env);
  } catch (e) {
    console.error('[notify] service account token failed', e);
    return json({ error: 'server_misconfigured' }, 500, cors);
  }

  const order = await firestoreGetFields(env, accessToken, `orders/${orderId}`);
  if (!order) return json({ error: 'order_not_found' }, 404, cors);
  const shop = await firestoreGetFields(env, accessToken, `shops/${order.shopId}`);
  if (!shop) return json({ error: 'shop_not_found' }, 404, cors);

  let targetUid;
  if (type === 'newOrder') {
    if (callerUid !== order.customerUid) return json({ error: 'forbidden' }, 403, cors);
    targetUid = shop.ownerUid;
  } else {
    if (callerUid !== shop.ownerUid) return json({ error: 'forbidden' }, 403, cors);
    targetUid = order.customerUid;
  }
  if (!targetUid) return json({ error: 'no_recipient' }, 404, cors);

  const targetUser = await firestoreGetFields(env, accessToken, `users/${targetUid}`);
  const fcmToken = targetUser?.fcmToken;
  if (!fcmToken) return json({ ok: true, skipped: 'no_token' }, 200, cors);

  try {
    await sendFcm(env, accessToken, { token: fcmToken, title, body: msgBody, data: { orderId, type } });
  } catch (e) {
    console.error('[notify] fcm send failed', e);
    return json({ error: 'send_failed' }, 502, cors);
  }
  return json({ ok: true }, 200, cors);
}

function bearer(request) {
  const m = (request.headers.get('authorization') ?? '').match(/^Bearer (.+)$/);
  return m ? m[1] : null;
}

async function verifyFirebaseToken(token, projectId) {
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
async function getServiceAccountToken(env) {
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

/** Reads one Firestore doc via REST and unwraps its typed fields to plain JS. */
async function firestoreGetFields(env, accessToken, path) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.PROJECT_ID}/databases/(default)/documents/${path}`,
    { headers: { authorization: `Bearer ${accessToken}` } },
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`firestore_get_${res.status}: ${await res.text()}`);
  const doc = await res.json();
  const out = {};
  for (const [k, v] of Object.entries(doc.fields ?? {})) {
    if (v.stringValue !== undefined) out[k] = v.stringValue;
    else if (v.integerValue !== undefined) out[k] = Number(v.integerValue);
    else if (v.booleanValue !== undefined) out[k] = v.booleanValue;
  }
  return out;
}

async function sendFcm(env, accessToken, { token, title, body, data }) {
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

function b64urlDecode(s) {
  return atob(s.replace(/-/g, '+').replace(/_/g, '/'));
}

function corsHeaders(env) {
  return {
    'access-control-allow-origin': env.ALLOWED_ORIGIN ?? '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
  };
}

function json(body, status, extra) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...extra },
  });
}
