import 'package:equatable/equatable.dart';

import 'address.dart';
import 'order_item.dart';
import 'order_status.dart';
import 'status_change.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.shopId,
    required this.customerUid,
    required this.items,
    required this.totalMinor,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
    this.notes,
    this.rating,
    this.statusHistory = const [],
    this.driverUid,
    this.driverName,
    this.driverPhone,
    this.assignedAt,
  });

  final String id;
  final String shopId;
  final String customerUid;
  final List<OrderItem> items;
  final int totalMinor;
  final OrderStatus status;
  final DateTime createdAt;
  final Address deliveryAddress;
  final String? notes;

  /// 1-5 stars the customer gave this shop after delivery (P3), or null if
  /// not rated yet. Set once — the repository rejects a second rate call.
  final int? rating;

  /// Timeline of every status the order has held, oldest first. Empty list
  /// for orders created before this field existed (seeded v1 orders).
  final List<StatusChange> statusHistory;

  /// Assigned delivery driver (Phase 5 M9 — shared driver pool). Null until
  /// the owner assigns one via the assignment transaction; the order detail
  /// page renders a driver block behind this null check. Name/phone are
  /// denormalized from the driver's profile at assignment time so both
  /// customer and owner views read them without an extra `/drivers` fetch.
  final String? driverUid;
  final String? driverName;
  final String? driverPhone;
  final DateTime? assignedAt;

  @override
  List<Object?> get props => [
        id,
        shopId,
        customerUid,
        items,
        totalMinor,
        status,
        createdAt,
        deliveryAddress,
        notes,
        rating,
        statusHistory,
        driverUid,
        driverName,
        driverPhone,
        assignedAt,
      ];
}
