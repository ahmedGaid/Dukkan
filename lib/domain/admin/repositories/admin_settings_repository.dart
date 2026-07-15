/// Founder Console platform-settings management (FC12). Both `/config/platform`
/// and `/config/flags` are Firestore-direct + a best-effort audit report,
/// gated by the `settings.edit` rules branch — no Worker-routed op here,
/// same shape as `AdminTaxonomyRepository`.
abstract class AdminSettingsRepository {
  /// Patches `/config/platform` with [fields] (a save-group's full set, even
  /// unchanged keys); [before]/[after] carry only the keys that actually
  /// changed, for the audit diff.
  Future<void> updateConfig({
    required Map<String, dynamic> fields,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  });

  /// Sets or adds one `/config/flags` entry.
  Future<void> setFlag({required String key, required bool value});

  Future<void> deleteFlag(String key);
}
