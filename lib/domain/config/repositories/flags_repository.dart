import '../entities/feature_flags.dart';

/// Feature-flags boundary — one-shot read of the founder-managed `/config/flags`
/// doc, same memoized-for-the-session contract as `PlatformConfigRepository`.
abstract class FlagsRepository {
  Future<FeatureFlags> getFlags();

  /// Clears the memo and refetches — called after a console save.
  Future<FeatureFlags> refresh();
}
