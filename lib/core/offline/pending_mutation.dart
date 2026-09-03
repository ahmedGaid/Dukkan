import '../../domain/order/entities/order_status.dart';

/// One queued order-status write, waiting for signal (O2 slice 1 —
/// `Docs/plan/offline-order-status-queue-design.md`). Persisted as JSON by
/// `OfflineMutationQueue`, so every field must round-trip losslessly —
/// [targetStatus] goes through `OrderStatus.wire`/`fromWire`, never the raw
/// enum index (an enum reorder must never silently corrupt a saved queue).
class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.orderId,
    required this.targetStatus,
    required this.actorUid,
    required this.enqueuedAt,
  });

  final String id;
  final String orderId;
  final OrderStatus targetStatus;
  final String actorUid;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'targetStatus': targetStatus.wire,
        'actorUid': actorUid,
        'enqueuedAt': enqueuedAt.toIso8601String(),
      };

  factory PendingMutation.fromJson(Map<String, dynamic> json) => PendingMutation(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        targetStatus: OrderStatus.fromWire(json['targetStatus'] as String),
        actorUid: json['actorUid'] as String,
        enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
      );
}
