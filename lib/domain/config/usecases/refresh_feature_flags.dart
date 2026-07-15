import '../entities/feature_flags.dart';
import '../repositories/flags_repository.dart';

class RefreshFeatureFlags {
  const RefreshFeatureFlags(this._repository);

  final FlagsRepository _repository;

  Future<FeatureFlags> call() => _repository.refresh();
}
