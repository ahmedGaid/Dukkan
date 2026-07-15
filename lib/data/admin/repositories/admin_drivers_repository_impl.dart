import 'dart:async';

import '../../../domain/admin/entities/driver_performance.dart';
import '../../../domain/admin/repositories/admin_drivers_repository.dart';
import '../../../domain/driver/entities/driver.dart';
import '../../../domain/order/entities/order.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_drivers_remote_datasource.dart';

/// No cache — the console must always reflect the latest activation/capacity
/// state (same contract as `AdminShopsRepositoryImpl`). Every mutation is
/// Firestore-direct + a best-effort [AdminApiDataSource.reportAudit]; there is
/// no Worker-routed op here, unlike shop ownership transfer.
class AdminDriversRepositoryImpl implements AdminDriversRepository {
  AdminDriversRepositoryImpl(this._remote, this._api);

  final AdminDriversRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<List<Driver>> getAllDrivers() => _remote.getAllDrivers();

  @override
  Future<Driver?> getDriverById(String uid) => _remote.getDriverById(uid);

  @override
  Future<void> setSuspended({
    required String uid,
    required bool value,
    String? reason,
  }) async {
    await _remote.patchFields(uid, {
      'isSuspended': value,
      'suspendReason': value ? reason : null,
    });
    unawaited(_api.reportAudit(
      action: value ? 'driver.suspend' : 'driver.activate',
      targetType: 'driver',
      targetId: uid,
      after: {'isSuspended': value},
      reason: reason,
    ));
  }

  @override
  Future<void> setVerified({required String uid, required bool value}) async {
    await _remote.patchFields(uid, {'isVerified': value});
    unawaited(_api.reportAudit(
      action: 'driver.verify',
      targetType: 'driver',
      targetId: uid,
      after: {'isVerified': value},
    ));
  }

  @override
  Future<void> updateDetails({
    required String uid,
    required String name,
    String? phone,
    required List<String> areaIds,
    required int maxActiveOrders,
    String? vehicleType,
    String? vehiclePlate,
    String? idDocUrl,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      // Unconditional (not `?field`) for the three text fields the console UI
      // lets staff clear back to empty — an explicit `null` write actually
      // clears the field; omitting the key would silently keep the old value.
      'phone': phone,
      'areaIds': areaIds,
      'maxActiveOrders': maxActiveOrders,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'idDocUrl': ?idDocUrl,
    };
    await _remote.patchFields(uid, fields);
    unawaited(_api.reportAudit(
      action: 'driver.update',
      targetType: 'driver',
      targetId: uid,
      after: fields,
    ));
  }

  @override
  Future<DriverPerformance> getPerformance(String uid) => _remote.getPerformance(uid);

  @override
  Future<List<Order>> getAssignedOrders(String uid) => _remote.getAssignedOrders(uid);
}
