import '../../../core/network/network_info.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/repositories/areas_repository.dart';
import '../datasources/areas_local_datasource.dart';
import '../datasources/areas_remote_datasource.dart';

class AreasRepositoryImpl implements AreasRepository {
  AreasRepositoryImpl(this._remote, this._local, this._networkInfo);

  final AreasRemoteDataSource _remote;
  final AreasLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Future<List<Area>> getAreas() async {
    if (await _networkInfo.isConnected) {
      final areas = await _remote.getAreas();
      await _local.cacheAreas(areas);
      return areas;
    }
    return _local.getCachedAreas();
  }
}
