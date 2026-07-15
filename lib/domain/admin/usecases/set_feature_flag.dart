import '../repositories/admin_settings_repository.dart';

class SetFeatureFlag {
  const SetFeatureFlag(this._repository);

  final AdminSettingsRepository _repository;

  Future<void> call({required String key, required bool value}) =>
      _repository.setFlag(key: key, value: value);
}
