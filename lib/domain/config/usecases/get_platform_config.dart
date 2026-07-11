import '../entities/platform_config.dart';
import '../repositories/platform_config_repository.dart';

/// Loads the founder-managed rate config (checkout's fee display, order
/// creation's commission snapshot). Thin pass-through — matches `GetAreas`.
class GetPlatformConfig {
  const GetPlatformConfig(this._repository);

  final PlatformConfigRepository _repository;

  Future<PlatformConfig> call() => _repository.getConfig();
}
