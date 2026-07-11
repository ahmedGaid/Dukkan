import 'package:dukkan/data/order/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderModel.fromFirestore driver fields (M9)', () {
    test('parses assigned driver fields', () {
      final order = OrderModel.fromFirestore('o1', {
        'shopId': 's1',
        'customerUid': 'u1',
        'items': [],
        'totalMinor': 1000,
        'status': 'accepted',
        'deliveryAddress': {'line1': 'Street 1', 'city': 'Cairo'},
        'driverUid': 'd1',
        'driverName': 'كريم',
        'driverPhone': '01011111111',
        'assignedAt': '2026-07-11T10:00:00.000',
      });

      expect(order.driverUid, 'd1');
      expect(order.driverName, 'كريم');
      expect(order.driverPhone, '01011111111');
      expect(order.assignedAt, DateTime.parse('2026-07-11T10:00:00.000'));
    });

    test('leaves driver fields null when unassigned', () {
      final order = OrderModel.fromFirestore('o1', {
        'shopId': 's1',
        'customerUid': 'u1',
        'items': [],
        'totalMinor': 1000,
        'status': 'pending',
        'deliveryAddress': {'line1': 'Street 1', 'city': 'Cairo'},
      });

      expect(order.driverUid, isNull);
      expect(order.driverName, isNull);
      expect(order.driverPhone, isNull);
      expect(order.assignedAt, isNull);
    });
  });
}
