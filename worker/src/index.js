/**
 * Dukkan Worker — image uploads (R2) + order push notifications (FCM v1) +
 * privileged Back-Office API.
 *
 * The Flutter app cannot hold R2 credentials or an FCM service account (an
 * APK is unpackable, so any embedded secret is effectively public). This
 * Worker is the trusted middle-man:
 *
 *   POST /upload   — app --(bytes + Bearer <Firebase ID token>)--> Worker
 *                    Worker verifies token -> env.BUCKET.put(key, bytes)
 *                    -> returns { url }
 *
 *   POST /notify   — app --(orderId/type/title/body + Bearer ID token)--> Worker
 *                    Worker verifies token, reads the order+shop from Firestore
 *                    (service account, bypasses security rules by design —
 *                    this is the trusted backend), checks the caller is a real
 *                    party to that order, resolves the *other* party's saved
 *                    FCM token, and sends via FCM HTTP v1.
 *                    -> returns { ok: true } (or a no-op if the recipient has
 *                    no token yet — not an error, just nothing to deliver to)
 *
 *   POST /admin/*  — Founder Console back-office ops. Permission-checked
 *                    against `/admins/{uid}` and audited server-side. See
 *                    `admin.js`.
 *
 * Shared Firebase plumbing (token verify, service-account token, Firestore
 * REST, FCM) lives in `firebase.js` so `/notify` and `/admin/*` share one
 * copy. Bindings (see wrangler.toml + `wrangler secret put`):
 *   BUCKET                    R2 bucket that stores uploaded images
 *   PROJECT_ID                Firebase project id (dukkan-93042)
 *   PUBLIC_BASE_URL           public-read origin for the bucket
 *   ALLOWED_ORIGIN            CORS origin for the app
 *   FIREBASE_SERVICE_ACCOUNT  secret — the Firebase service-account JSON key.
 */
import {
  verifyFirebaseToken,
  getServiceAccountToken,
  firestoreGetFields,
  sendFcm,
  bearer,
  json,
} from './firebase.js';
import { handleAdmin } from './admin.js';

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB — a logo / product photo, not a video
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_FOLDERS = new Set(['shop-logos', 'product-images']);
const NOTIFY_TYPES = new Set(['newOrder', 'statusUpdate', 'driverAssigned', 'orderDelivered']);

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
    if (pathname.startsWith('/admin/')) return handleAdmin(request, env, cors);
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
 * Authorization model: the caller must be one of the real parties to the
 * order, and can only notify the party the type concerns — never an
 * arbitrary uid, and never a party the type isn't for (M11, Task B: a
 * courier sits on the order too now, but has no notify type of its own —
 * it must not be able to trigger `newOrder`/`statusUpdate`, which is
 * naturally true below since neither branch's caller check can match a
 * `driverUid` that differs from `customerUid`/`shop.ownerUid`).
 *   newOrder       — caller must be the order's customer; target = shop owner.
 *   statusUpdate   — caller must be the shop's owner;    target = customer.
 *   driverAssigned — caller must be the shop's owner;    target = order's driver.
 *   orderDelivered — caller must be the order's driver;  target = shop owner.
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
  } else if (type === 'statusUpdate') {
    if (callerUid !== shop.ownerUid) return json({ error: 'forbidden' }, 403, cors);
    targetUid = order.customerUid;
  } else if (type === 'driverAssigned') {
    if (callerUid !== shop.ownerUid) return json({ error: 'forbidden' }, 403, cors);
    targetUid = order.driverUid;
  } else {
    // orderDelivered
    if (callerUid !== order.driverUid) return json({ error: 'forbidden' }, 403, cors);
    targetUid = shop.ownerUid;
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

function corsHeaders(env) {
  return {
    'access-control-allow-origin': env.ALLOWED_ORIGIN ?? '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
  };
}
