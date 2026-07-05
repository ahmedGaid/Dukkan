import 'package:equatable/equatable.dart';

import 'address.dart';
import 'order_item.dart';
import 'order_status.dart';

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
      ];
}
