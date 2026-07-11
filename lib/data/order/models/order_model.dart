// `Order` also exists in cloud_firestore_platform_interface (query direction
// enum) — hide it so the domain `Order` entity wins unqualified.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/entities/status_change.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.shopId,
    required super.customerUid,
    required super.items,
    required super.totalMinor,
    required super.status,
    required super.createdAt,
    required super.deliveryAddress,
    super.notes,
    super.rating,
    super.statusHistory,
    super.driverUid,
    super.driverName,
    super.driverPhone,
    super.assignedAt,
  });

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawItems = List<Map<String, dynamic>>.from(
      (data['items'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final rawAddress = Map<String, dynamic>.from(
      data['deliveryAddress'] as Map? ?? const {},
    );
    final createdAt = data['createdAt'];
    return OrderModel(
      id: id,
      shopId: data['shopId'] as String? ?? '',
      customerUid: data['customerUid'] as String? ?? '',
      items: rawItems.map(_itemFromMap).toList(),
      totalMinor: (data['totalMinor'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromWire(data['status'] as String? ?? ''),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      deliveryAddress: Address(
        line1: rawAddress['line1'] as String? ?? '',
        city: rawAddress['city'] as String? ?? '',
        notes: rawAddress['notes'] as String?,
        areaId: rawAddress['areaId'] as String?,
      ),
      notes: data['notes'] as String?,
      rating: (data['rating'] as num?)?.toInt(),
      statusHistory: (data['statusHistory'] as List? ?? const [])
          .map((e) => _statusChangeFromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      driverUid: data['driverUid'] as String?,
      driverName: data['driverName'] as String?,
      driverPhone: data['driverPhone'] as String?,
      assignedAt: data['assignedAt'] != null
          ? DateTime.parse(data['assignedAt'] as String)
          : null,
    );
  }

  static StatusChange _statusChangeFromMap(Map<String, dynamic> map) =>
      StatusChange(
        status: OrderStatus.fromWire(map['status'] as String? ?? ''),
        at: DateTime.parse(map['at'] as String),
        byUid: map['byUid'] as String? ?? '',
      );

  static Map<String, dynamic> _statusChangeToMap(StatusChange change) => {
        'status': change.status.wire,
        'at': change.at.toIso8601String(),
        'byUid': change.byUid,
      };

  static OrderItem _itemFromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        nameAr: map['nameAr'] as String? ?? '',
        priceMinor: (map['priceMinor'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> _itemToMap(OrderItem item) => {
        'productId': item.productId,
        'name': item.name,
        'nameAr': item.nameAr,
        'priceMinor': item.priceMinor,
        'quantity': item.quantity,
      };

  Map<String, dynamic> toFirestore() => {
        'shopId': shopId,
        'customerUid': customerUid,
        'items': items.map(_itemToMap).toList(),
        'totalMinor': totalMinor,
        'status': status.wire,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveryAddress': {
          'line1': deliveryAddress.line1,
          'city': deliveryAddress.city,
          if (deliveryAddress.notes != null) 'notes': deliveryAddress.notes,
          if (deliveryAddress.areaId != null) 'areaId': deliveryAddress.areaId,
        },
        if (notes != null) 'notes': notes,
        'statusHistory': statusHistory.map(_statusChangeToMap).toList(),
      };
}
