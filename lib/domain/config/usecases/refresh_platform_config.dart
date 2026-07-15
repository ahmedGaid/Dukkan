import '../entities/platform_config.dart';
import '../repositories/platform_config_repository.dart';

/// Clears the memo and refetches — the console calls this right after a
/// settings save so the same app process sees its own write.
class RefreshPlatformConfig {
  const RefreshPlatformConfig(this._repository);

  final PlatformConfigRepository _repository;

  Future<PlatformConfig> call() => _repository.refresh();
}
