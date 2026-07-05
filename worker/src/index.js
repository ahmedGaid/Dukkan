/**
 * Dukkan image-upload Worker.
 *
 * The Flutter app cannot hold R2 credentials — an APK is unpackable, so any
 * embedded secret is effectively public. This Worker is the trusted middle-man:
 * it holds the R2 binding, verifies the caller is a real signed-in Dukkan user
 * (Firebase ID token), stores the image in R2, and returns its public URL. The
 * app only ever knows this Worker's URL — nothing extractable ships in it.
 *
 *   app --(POST bytes + `Authorization: Bearer <Firebase ID token>`)--> Worker
 *   Worker verifies token -> env.BUCKET.put(key, bytes) -> returns { url }
 *
 * Bindings (see wrangler.toml):
 *   BUCKET           R2 bucket that stores the images
 *   PROJECT_ID       Firebase project id (dukkan-93042) — token aud/iss check
 *   PUBLIC_BASE_URL  public-read origin for the bucket (r2.dev or custom domain)
 *   ALLOWED_ORIGIN   CORS origin for the app ("*" is fine while testing)
 */
import { importX509, jwtVerify } from 'jose';

// Firebase session tokens are signed by this Google service account. Its public
// keys are published only as X.509 certs here (there is no JWK endpoint for
// them) — `jose.importX509` turns each PEM into a verify key.
const GOOGLE_CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB — a logo / product photo, not a video
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const ALLOWED_FOLDERS = new Set(['shop-logos', 'product-images']);

// Cert cache, module scope: survives across requests on a warm isolate so we
// don't refetch Google's certs on every upload.
let certCache = { certs: null, expiresAt: 0 };

export default {
  async fetch(request, env) {
    const cors = corsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    if (request.method !== 'POST') {
      return json({ error: 'method_not_allowed' }, 405, cors);
    }

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
  },
};

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
