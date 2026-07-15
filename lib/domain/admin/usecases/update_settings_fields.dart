import '../repositories/admin_settings_repository.dart';

/// Patches one `/config/platform` save-group (rates, contact, or app gates —
/// `SettingsPage` decides which fields). Thin pass-through — matches
/// `UpdateDriver`.
class UpdateSettingsFields {
  const UpdateSettingsFields(this._repository);

  final AdminSettingsRepository _repository;

  Future<void> call({
    required Map<String, dynamic> fields,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) =>
      _repository.updateConfig(fields: fields, before: before, after: after);
}
