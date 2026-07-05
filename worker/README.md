# Dukkan image-upload Worker

Secure middle-man for image uploads. The Flutter app can't hold R2 keys (an APK
is unpackable), so it POSTs image bytes here with the user's Firebase ID token;
this Worker verifies the token, stores the file in R2, and returns its public
URL. See `src/index.js` for the full flow.

```
app --(POST bytes + Bearer <Firebase ID token>)--> Worker
     Worker verifies token -> R2 put -> { "url": "https://.../key.jpg" }
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
  (no service-account secret needed in the Worker).
- **Limits:** 5 MB max, `image/jpeg | image/png | image/webp` only, folders
  restricted to `shop-logos` and `product-images` (must match the app's
  `StorageFolder` constants).
- **Keys** are namespaced `folder/<uid>/<uuid>.<ext>` so one user can't
  overwrite another's file.
