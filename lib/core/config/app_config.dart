/// App-wide configuration constants.
///
/// [workerBaseUrl] is the Cloudflare Worker that fronts both image uploads
/// (R2) and push-notification sends (FCM v1) — see `worker/` at the repo
/// root. The app never talks to R2 or FCM directly — it POSTs to this
/// Worker, which verifies the caller's Firebase ID token and does the
/// trusted work server-side.
///
/// **Stub until the Worker is deployed.** Deploy `worker/` (`wrangler deploy`),
/// then either paste the printed `*.workers.dev` URL over [_stub] below, or pass
/// it without editing code:
///   `flutter run --dart-define=UPLOAD_WORKER_URL=https://…workers.dev`
/// Until then [workerConfigured] is false and the upload/notify layers fail
/// fast (or no-op) with a clear message instead of hitting a dead host.
class AppConfig {
  const AppConfig._();

  /// App version shown on the settings page. Bump this alongside the
  /// `version:` line in `pubspec.yaml` — there's no `package_info` dependency
  /// (kept lean), so the two are synced by hand.
  static const String version = '1.0.0';

  /// The `+N` build number from pubspec `version: x.y.z+N` (currently `+1`).
  /// Compared against `PlatformConfig.minSupportedBuild` at boot (M12 Task D)
  /// — same hand-sync note as [version].
  static const int buildNumber = 1;

  static const String _stub = 'https://REPLACE-ME.workers.dev';

  static const String workerBaseUrl =
      String.fromEnvironment('UPLOAD_WORKER_URL', defaultValue: _stub);

  static bool get workerConfigured => workerBaseUrl != _stub;

  /// The R2 public-read origin (`PUBLIC_BASE_URL` in `worker/wrangler.toml`).
  /// The `/upload` response already returns a full URL, but `/admin/media/*`
  /// returns bare keys (FC14) — the console composes `mediaPublicBaseUrl/key`
  /// itself, same scheme the Worker uses server-side.
  static const String _mediaStub = 'https://REPLACE-WITH-YOUR-R2-PUBLIC-URL';

  static const String mediaPublicBaseUrl =
      String.fromEnvironment('MEDIA_PUBLIC_BASE_URL', defaultValue: _mediaStub);

  /// The one account allowed onto the finance summary (M13) — a v1 stopgap
  /// gate until a real admin-role system exists. Mirrors the literal uid in
  /// `firestore.rules`' `isFounder()`; both must be updated together if the
  /// founder account ever changes.
  static const String founderUid = 'LPPjx32MJpWlMR3SEksJ7sY2NAF2';

  /// Firebase project ids devtools' destructive re-seed tool (FC15) is
  /// allowed to run against. A founder always clears the RBAC/permission
  /// gate, so this is the second, project-identity gate — keeps a re-seed
  /// from ever reaching a real production project once one exists
  /// alongside this one. Update if/when the project ever splits.
  static const devProjectIds = <String>['dukkan-93042'];
}
