import '../../../domain/driver/entities/driver.dart';
import '../../../domain/driver/repositories/driver_repository.dart';
import '../datasources/driver_remote_datasource.dart';

class DriverRepositoryImpl implements DriverRepository {
  DriverRepositoryImpl(this._remote);

  final DriverRemoteDataSource _remote;

  @override
  Future<void> createDriverProfile({
    required String uid,
    required String name,
    String? phone,
  }) =>
      _remote.createDriverProfile(uid: uid, name: name, phone: phone);

  @override
  Future<Driver?> getDriver(String uid) => _remote.getDriver(uid);

  @override
  Stream<Driver?> watchDriver(String uid) => _remote.watchDriver(uid);

  @override
  Future<void> setOnline(String uid, bool isOnline) =>
      _remote.setOnline(uid, isOnline);

  @override
  Future<List<Driver>> availableDrivers(String areaId) =>
      _remote.availableDrivers(areaId);
}
