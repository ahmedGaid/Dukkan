/// App-wide configuration constants.
///
/// [uploadWorkerBaseUrl] is the Cloudflare Worker that fronts R2 image uploads
/// (see `worker/` at the repo root). The app never talks to R2 directly — it
/// POSTs image bytes to this Worker, which verifies the caller's Firebase ID
/// token and stores the file.
///
/// **Stub until the Worker is deployed.** Deploy `worker/` (`wrangler deploy`),
/// then either paste the printed `*.workers.dev` URL over [_stub] below, or pass
/// it without editing code:
///   `flutter run --dart-define=UPLOAD_WORKER_URL=https://…workers.dev`
/// Until then [uploadConfigured] is false and the upload layer fails fast with a
/// clear message instead of hitting a dead host.
class AppConfig {
  const AppConfig._();

  static const String _stub = 'https://REPLACE-ME.workers.dev';

  static const String uploadWorkerBaseUrl =
      String.fromEnvironment('UPLOAD_WORKER_URL', defaultValue: _stub);

  static bool get uploadConfigured => uploadWorkerBaseUrl != _stub;
}
