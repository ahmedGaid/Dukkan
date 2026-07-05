# Dukkan Worker — image uploads + order push notifications

Secure middle-man for two things the Flutter app can't do itself (an APK is
unpackable, so no secret can live in it): uploading images to R2, and sending
FCM push notifications. See `src/index.js` for the full flow of each.

```
POST /upload  app --(bytes + Bearer <Firebase ID token>)--> Worker
              Worker verifies token -> R2 put -> { "url": "https://.../key.jpg" }

POST /notify  app --(orderId/type/title/body + Bearer ID token)--> Worker
              Worker verifies token, checks the caller is a real party to
              that order (via Firestore), resolves the other party's saved
              FCM token, and sends -> { "ok": true }
```

## One-time setup (you run these — Cloudflare login can't run in the agent shell)

Prereqs: a Cloudflare account, and Node installed.

```bash
cd worker
npm install                 # pulls jose + wrangler locally
npx wrangler login          # opens a browser to authorize

# 1. Create the R2 bucket (name must match wrangler.toml -> bucket_name)
npx wrangler r2 bucket create dukkan-images
```

Then enable **public read** on the bucket so the app can display images:
Cloudflare dashboard → R2 → `dukkan-images` → **Settings → Public access** →
allow, and copy the `https://pub-xxxxxxxx.r2.dev` URL it gives you.

## Configure

Edit `wrangler.toml` → `[vars]`:

- `PUBLIC_BASE_URL` → paste the `pub-….r2.dev` URL from the step above.
- `ALLOWED_ORIGIN` → leave `"*"` for testing; set to the app origin for prod.
- `PROJECT_ID` → already `dukkan-93042` (change only if the Firebase project does).

Then set the notify secret (needed for `/notify`, not `/upload`):

1. Firebase console → gear icon → **Project settings → Service accounts** →
   **Generate new private key**. Downloads a JSON file — keep it private,
   never commit it.
2. `cd worker && npx wrangler secret put FIREBASE_SERVICE_ACCOUNT`, then paste
   the **entire contents** of that JSON file (one line is fine) and press
   Enter.

## Deploy

```bash
cd worker
npx wrangler deploy
```

Wrangler prints the live URL, e.g. `https://dukkan-uploads.<subdomain>.workers.dev`.

## Point the app at it

Put that URL in the Flutter app. Two ways:

- Quick: edit `lib/core/config/app_config.dart` → replace the `_stub` value.
- Cleaner (no code edit): pass it at run/build time —
  `flutter run --dart-define=UPLOAD_WORKER_URL=https://dukkan-uploads.<subdomain>.workers.dev`

Until this is done the app's upload layer fails fast with a clear "not
configured" error instead of hitting a dead host.

## Notes

- **Auth:** every request must carry a valid Firebase ID token for project
  `dukkan-93042`. Verification uses Google's published X.509 certs via `jose`
  (no service-account secret needed for this check).
- **Upload limits:** 5 MB max, `image/jpeg | image/png | image/webp` only,
  folders restricted to `shop-logos` and `product-images` (must match the
  app's `StorageFolder` constants). Keys are namespaced
  `folder/<uid>/<uuid>.<ext>` so one user can't overwrite another's file.
- **Notify authorization:** `/notify` only ever lets the two real parties to
  an order message each other — a customer can trigger `newOrder` only for
  their own order (target = that shop's owner), a shop owner can trigger
  `statusUpdate` only for their own shop's order (target = that order's
  customer). The Worker derives both uids itself from Firestore; the app
  can't spoof a target. If the recipient hasn't granted notification
  permission yet (no saved `fcmToken`), the call is a silent no-op, not an
  error — never blocks placing/advancing an order.
- **Push text i18n:** the Worker doesn't know either user's language
  preference, so it sends whatever `title`/`body` the app provides as-is —
  the app composes them bilingually (ar + en) at call time. See
  `lib/data/notifications/datasources/notification_remote_datasource.dart`.
