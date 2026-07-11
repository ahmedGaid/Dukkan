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

  group('OrderModel.fromFirestore commission fields (M12)', () {
    test('parses a full commission snapshot', () {
      final order = OrderModel.fromFirestore('o1', {
        'shopId': 's1',
        'customerUid': 'u1',
        'items': [],
        'totalMinor': 8000,
        'subtotalMinor': 5000,
        'deliveryFeeMinor': 3000,
        'commissionBps': 500,
        'commissionMinor': 250,
        'driverDeliveryShareMinor': 2500,
        'platformDeliveryShareMinor': 500,
        'commissionPayable': true,
        'status': 'delivered',
        'deliveryAddress': {'line1': 'Street 1', 'city': 'Cairo'},
      });

      expect(order.subtotalMinor, 5000);
      expect(order.deliveryFeeMinor, 3000);
      expect(order.commissionBps, 500);
      expect(order.commissionMinor, 250);
      expect(order.driverDeliveryShareMinor, 2500);
      expect(order.platformDeliveryShareMinor, 500);
      expect(order.commissionPayable, isTrue);
    });

    test('pre-M12 doc with no commission fields falls back to defaults', () {
      final order = OrderModel.fromFirestore('o1', {
        'shopId': 's1',
        'customerUid': 'u1',
        'items': [],
        'totalMinor': 6500,
        'status': 'delivered',
        'deliveryAddress': {'line1': 'Street 1', 'city': 'Cairo'},
      });

      expect(order.subtotalMinor, 6500); // falls back to totalMinor
      expect(order.deliveryFeeMinor, 0);
      expect(order.commissionBps, 0);
      expect(order.commissionMinor, 0);
      expect(order.driverDeliveryShareMinor, 0);
      expect(order.platformDeliveryShareMinor, 0);
      expect(order.commissionPayable, isFalse);
    });
  });
}
