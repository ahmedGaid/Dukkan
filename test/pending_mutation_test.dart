import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson/fromJson round-trips every field', () {
    final original = PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.preparing,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11, 10, 30),
    );

    final restored = PendingMutation.fromJson(original.toJson());

    expect(restored.id, 'm1');
    expect(restored.orderId, 'o1');
    expect(restored.targetStatus, OrderStatus.preparing);
    expect(restored.actorUid, 'u1');
    expect(restored.enqueuedAt, DateTime(2026, 8, 11, 10, 30));
  });

  test('targetStatus round-trips via the wire form, not the enum index', () {
    final json = PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.rejected,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 1, 1),
    ).toJson();

    expect(json['targetStatus'], 'rejected');
  });
}
