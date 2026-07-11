import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/entities/status_change.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  Future<OrderModel> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final draft = OrderModel(
        id: '',
        shopId: shopId,
        customerUid: customerUid,
        items: items,
        totalMinor: totalMinor,
        status: OrderStatus.pending,
        createdAt: now,
        deliveryAddress: deliveryAddress,
        notes: notes,
        statusHistory: [
          StatusChange(status: OrderStatus.pending, at: now, byUid: customerUid),
        ],
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

  static const _driverActiveStatuses = [
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
  ];

  /// The courier's active-deliveries tab (Session 10) — no `orderBy` (a
  /// composite index on `driverUid`+`status` covers the equality+`in` filter);
  /// sorted client-side by the bloc instead.
  Stream<List<OrderModel>> watchDriverActiveOrders(String driverUid) {
    return _orders
        .where('driverUid', isEqualTo: driverUid)
        .where('status', whereIn: _driverActiveStatuses.map((s) => s.wire).toList())
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// The courier's history tab (Session 10) — delivered only, newest first,
  /// capped at 20 so a long-tenured driver's read cost stays bounded.
  Stream<List<OrderModel>> watchDriverHistory(String driverUid) {
    return _orders
        .where('driverUid', isEqualTo: driverUid)
        .where('status', isEqualTo: OrderStatus.delivered.wire)
        .orderBy('assignedAt', descending: true)
        .limit(20)
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

  Future<void> cancelOrder(String orderId) => _advanceStatus(
        orderId,
        OrderStatus.cancelled,
      );

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _advanceStatus(orderId, status);

  static const _terminalStatuses = {
    OrderStatus.delivered,
    OrderStatus.cancelled,
    OrderStatus.rejected,
  };

  Future<void> _advanceStatus(String orderId, OrderStatus status) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw const ServerFailure('Not signed in');
      }
      final orderRef = _orders.doc(orderId);
      final change = {
        'status': status.wire,
        'at': DateTime.now().toIso8601String(),
        'byUid': uid,
      };

      // A driver-carrying order reaching a terminal status frees its slot on
      // the driver's profile — done inside the same transaction as the
      // status write so the count never drifts from reality.
      if (!_terminalStatuses.contains(status)) {
        await orderRef.update({
          'status': status.wire,
          'statusHistory': FieldValue.arrayUnion([change]),
        });
        return;
      }

      await _firestore.runTransaction((txn) async {
        // Firestore transactions require every read before any write, so the
        // driver doc (if any) is read here, ahead of both updates below.
        final orderSnap = await txn.get(orderRef);
        final driverUid = orderSnap.data()?['driverUid'] as String?;
        final driverRef = driverUid == null ? null : _drivers.doc(driverUid);
        final active = driverRef == null
            ? 0
            : ((await txn.get(driverRef)).data()?['activeOrdersCount'] as num?)
                    ?.toInt() ??
                0;

        txn.update(orderRef, {
          'status': status.wire,
          'statusHistory': FieldValue.arrayUnion([change]),
        });
        if (driverRef != null) {
          txn.update(driverRef, {
            'activeOrdersCount': active > 0 ? active - 1 : 0,
          });
        }
      });
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
