import '../entities/platform_config.dart';

/// Platform config boundary — one-shot read of the founder-managed rate doc.
/// Not a stream: rates only change via console/re-seed, same contract as
/// `AreasRepository.getAreas`. The implementation caches the result for the
/// app session so a checkout never pays a round-trip for it.
abstract class PlatformConfigRepository {
  Future<PlatformConfig> getConfig();
}
