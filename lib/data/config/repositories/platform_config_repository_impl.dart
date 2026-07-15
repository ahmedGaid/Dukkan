import '../../../domain/config/entities/platform_config.dart';
import '../../../domain/config/repositories/platform_config_repository.dart';
import '../datasources/platform_config_remote_datasource.dart';

/// Memoizes the single remote read for the lifetime of the app process (the
/// repository itself is a DI lazy singleton, so a cold app start is the only
/// "refresh" point — see `PlatformConfigRepository` doc). No offline branch:
/// the config only ever changes via console/re-seed, never client-written.
/// Only a successful read is cached, so a transient failure (offline at
/// first checkout) doesn't pin the error for the rest of the session.
class PlatformConfigRepositoryImpl implements PlatformConfigRepository {
  PlatformConfigRepositoryImpl(this._remote);

  final PlatformConfigRemoteDataSource _remote;

  PlatformConfig? _cached;

  @override
  Future<PlatformConfig> getConfig() async {
    final cached = _cached;
    if (cached != null) return cached;
    return refresh();
  }

  @override
  Future<PlatformConfig> refresh() async {
    final config = await _remote.getConfig();
    _cached = config;
    return config;
  }
}
