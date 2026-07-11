import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/domain/driver/entities/driver.dart';
import 'package:dukkan/domain/driver/repositories/driver_repository.dart';
import 'package:dukkan/domain/driver/usecases/assign_driver.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDriverRepository implements DriverRepository {
  Object? errorToThrow;
  String? lastOrderId;
  String? lastDriverUid;

  @override
  Future<void> assignDriver({
    required String orderId,
    required String driverUid,
  }) async {
    lastOrderId = orderId;
    lastDriverUid = driverUid;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<List<Driver>> availableDrivers(String areaId) async => const [];

  @override
  Future<void> createDriverProfile({
    required String uid,
    required String name,
    String? phone,
  }) =>
      throw UnimplementedError();

  @override
  Future<Driver?> getDriver(String uid) => throw UnimplementedError();

  @override
  Future<void> setOnline(String uid, bool isOnline) =>
      throw UnimplementedError();

  @override
  Stream<Driver?> watchDriver(String uid) => throw UnimplementedError();
}

void main() {
  test('calls the repository with the given order/driver ids', () async {
    final repo = _FakeDriverRepository();
    final usecase = AssignDriver(repo);

    await usecase(orderId: 'o1', driverUid: 'd1');

    expect(repo.lastOrderId, 'o1');
    expect(repo.lastDriverUid, 'd1');
  });

  test('propagates DriverUnavailable from the repository', () async {
    final repo = _FakeDriverRepository()
      ..errorToThrow = const DriverUnavailable(DriverUnavailableReason.capacity);
    final usecase = AssignDriver(repo);

    await expectLater(
      () => usecase(orderId: 'o1', driverUid: 'd1'),
      throwsA(isA<DriverUnavailable>()
          .having((e) => e.reason, 'reason', DriverUnavailableReason.capacity)),
    );
  });
}
