import '../../../domain/config/entities/feature_flags.dart';
import '../../../domain/config/repositories/flags_repository.dart';
import '../datasources/flags_remote_datasource.dart';

/// Memoizes the single remote read for the app session — mirrors
/// `PlatformConfigRepositoryImpl`.
class FlagsRepositoryImpl implements FlagsRepository {
  FlagsRepositoryImpl(this._remote);

  final FlagsRemoteDataSource _remote;

  FeatureFlags? _cached;

  @override
  Future<FeatureFlags> getFlags() async {
    final cached = _cached;
    if (cached != null) return cached;
    return refresh();
  }

  @override
  Future<FeatureFlags> refresh() async {
    final flags = await _remote.getFlags();
    _cached = flags;
    return flags;
  }
}
