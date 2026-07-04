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
      ];
}
