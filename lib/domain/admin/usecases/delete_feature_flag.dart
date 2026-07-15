import '../repositories/admin_settings_repository.dart';

class DeleteFeatureFlag {
  const DeleteFeatureFlag(this._repository);

  final AdminSettingsRepository _repository;

  Future<void> call(String key) => _repository.deleteFlag(key);
}
