import '../entities/feature_flags.dart';
import '../repositories/flags_repository.dart';

/// Thin pass-through — matches `GetPlatformConfig`.
class GetFeatureFlags {
  const GetFeatureFlags(this._repository);

  final FlagsRepository _repository;

  Future<FeatureFlags> call() => _repository.getFlags();
}
