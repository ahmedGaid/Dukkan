import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  Future<OrderModel> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) async {
    try {
      final draft = OrderModel(
        id: '',
        shopId: shopId,
        customerUid: customerUid,
        items: items,
        totalMinor: totalMinor,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        deliveryAddress: deliveryAddress,
        notes: notes,
      );
      final ref = await _orders.add(draft.toFirestore());
      final saved = await ref.get();
      return OrderModel.fromFirestore(saved.id, saved.data()!);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Stream<List<OrderModel>> watchCustomerOrders(String customerUid) {
    return _orders
        .where('customerUid', isEqualTo: customerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<OrderModel>> watchShopOrders(String shopId) {
    return _orders
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<OrderModel> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        throw ServerFailure('Order $orderId not found');
      }
      return OrderModel.fromFirestore(doc.id, data);
    });
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _orders.doc(orderId).update({'status': OrderStatus.cancelled.wire});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _orders.doc(orderId).update({'status': status.wire});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// Reads the order first (inside the transaction) so a second rate call on
  /// an already-rated order throws instead of double-counting the shop's
  /// aggregate — mirrors the favorites toggle's read-then-write guard.
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) async {
    try {
      final orderRef = _orders.doc(orderId);
      final shopRef = _shops.doc(shopId);
      await _firestore.runTransaction((tx) async {
        final orderSnap = await tx.get(orderRef);
        if (orderSnap.data()?['rating'] != null) {
          throw const ServerFailure('Order already rated');
        }
        tx.update(orderRef, {'rating': rating});
        tx.update(shopRef, {
          'ratingSum': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
        });
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
