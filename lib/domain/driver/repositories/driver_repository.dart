import '../entities/driver.dart';

/// Driver-profile boundary. No local cache — always-online realtime data,
/// same reasoning as `CollectionsRepository`.
abstract class DriverRepository {
  /// Written once at courier signup, suspended by default.
  Future<void> createDriverProfile({
    required String uid,
    required String name,
    String? phone,
  });

  Future<Driver?> getDriver(String uid);

  Stream<Driver?> watchDriver(String uid);

  /// The signed-in driver flipping their own online/offline switch — the
  /// only field a driver can write on their own doc.
  Future<void> setOnline(String uid, bool isOnline);

  /// Active, unsuspended drivers covering [areaId] — the owner assignment
  /// list (Session 9).
  Future<List<Driver>> availableDrivers(String areaId);

  /// Owner assigns [driverUid] to [orderId] — a transaction validating
  /// capacity/area/status/online, throwing [DriverUnavailable] on rejection.
  /// See `FILE_09_ASSIGNMENT_TXN.md` Task B.
  Future<void> assignDriver({required String orderId, required String driverUid});
}
