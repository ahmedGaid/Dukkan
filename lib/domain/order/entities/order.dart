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
    int? subtotalMinor,
    this.deliveryFeeMinor = 0,
    this.commissionBps = 0,
    this.commissionMinor = 0,
    this.driverDeliveryShareMinor = 0,
    this.platformDeliveryShareMinor = 0,
    this.commissionPayable = false,
  }) : subtotalMinor = subtotalMinor ?? totalMinor;

  final String id;
  final String shopId;
  final String customerUid;
  final List<OrderItem> items;
  final int totalMinor;
  final OrderStatus status;
  final DateTime createdAt;
  final Address deliveryAddress;
  final String? notes;

  /// Items-only total, rate/fee-free (M12). Orders created before this field
  /// existed have no stored value — falls back to [totalMinor] (which was
  /// items-only too, before delivery fees existed).
  final int subtotalMinor;

  /// Customer-facing delivery fee snapshot at creation time. 0 for orders
  /// created before M12.
  final int deliveryFeeMinor;

  /// Commission rate (basis points) snapshot at creation time — kept even
  /// though the platform default can change later, so past orders read the
  /// rate that actually applied to them.
  final int commissionBps;

  /// Commission owed on this order, computed once at creation
  /// (round-half-up — see `PlatformConfig.commissionForSubtotal`).
  final int commissionMinor;
  final int driverDeliveryShareMinor;
  final int platformDeliveryShareMinor;

  /// Flips to true when the order reaches `delivered` — the point the
  /// commission is actually owed to the platform (M12 Task D). Stays false
  /// for cancelled/rejected orders even though the numbers remain on the doc.
  final bool commissionPayable;

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
        subtotalMinor,
        deliveryFeeMinor,
        commissionBps,
        commissionMinor,
        driverDeliveryShareMinor,
        platformDeliveryShareMinor,
        commissionPayable,
      ];
}
