import 'package:dukkan/data/driver/models/driver_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromFirestore parses a driver profile', () {
    final driver = DriverModel.fromFirestore('driver1', {
      'name': 'كريم',
      'phone': '01011111111',
      'areaIds': ['abu-atwa'],
      'maxActiveOrders': 5,
      'activeOrdersCount': 2,
      'isOnline': true,
      'isSuspended': false,
    });

    expect(driver.uid, 'driver1');
    expect(driver.name, 'كريم');
    expect(driver.phone, '01011111111');
    expect(driver.areaIds, ['abu-atwa']);
    expect(driver.maxActiveOrders, 5);
    expect(driver.activeOrdersCount, 2);
    expect(driver.isOnline, isTrue);
    expect(driver.isSuspended, isFalse);
  });

  test('fromFirestore defaults a missing doc safely', () {
    final driver = DriverModel.fromFirestore('driver1', const {});

    expect(driver.name, '');
    expect(driver.areaIds, isEmpty);
    expect(driver.maxActiveOrders, 5);
    expect(driver.activeOrdersCount, 0);
    expect(driver.isOnline, isFalse);
    // Every new driver starts suspended by default.
    expect(driver.isSuspended, isTrue);
  });

  test('newProfile is suspended and offline with zero active orders', () {
    final driver =
        DriverModel.newProfile(uid: 'driver1', name: 'كريم', phone: '010');

    expect(driver.isSuspended, isTrue);
    expect(driver.isOnline, isFalse);
    expect(driver.activeOrdersCount, 0);
    expect(driver.areaIds, isEmpty);
  });

  test('toFirestore carries the writable fields', () {
    final driver = DriverModel.newProfile(uid: 'driver1', name: 'كريم');

    final data = driver.toFirestore();

    expect(data['name'], 'كريم');
    expect(data.containsKey('phone'), isFalse);
    expect(data['isSuspended'], isTrue);
    expect(data['isOnline'], isFalse);
  });
}
