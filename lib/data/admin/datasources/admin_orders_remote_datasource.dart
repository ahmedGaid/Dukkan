import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/admin/entities/orders_page.dart';
import '../../order/models/order_model.dart';
import '../../order/models/order_note_model.dart';

/// Firestore-direct reads of `/orders` for the console board (rules allow it
/// via `hasPerm('orders.read')`) plus the notes subcollection (`orders.update`
/// branch). The three correction ops (force-status/reassign/cancel) are
/// Worker-routed — see `AdminOrdersRepositoryImpl`, not here.
class AdminOrdersRemoteDataSource {
  AdminOrdersRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const pageSize = 20;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  /// [status] is the one server-side equality facet — see `AdminOrdersRepository`
  /// doc for why shop/area/date-range are refined client-side instead.
  Future<OrdersPage> getOrders({String? status, DateTime? cursor}) async {
    try {
      Query<Map<String, dynamic>> q = _orders;
      if (status != null) q = q.where('status', isEqualTo: status);
      q = q.orderBy('createdAt', descending: true);
      if (cursor != null) q = q.startAfter([Timestamp.fromDate(cursor)]);
      q = q.limit(pageSize);

      final snap = await q.get();
      final orders = snap.docs
          .map((d) => OrderModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
      return OrdersPage(orders: orders, hasMore: orders.length == pageSize);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      final data = doc.data();
      if (data == null) return null;
      return OrderModel.fromFirestore(doc.id, data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<List<OrderModel>> getOrdersByCustomerUid(String customerUid) async {
    try {
      final snap = await _orders
          .where('customerUid', isEqualTo: customerUid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => OrderModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Stream<List<OrderNoteModel>> watchNotes(String orderId) {
    return _orders
        .doc(orderId)
        .collection('notes')
        .orderBy('at')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderNoteModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  /// `byName` is looked up from the signed-in staff member's own `/users`
  /// doc at write time — a fresh read per note, but notes are an occasional
  /// action, not a hot path.
  Future<void> addNote({required String orderId, required String text}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const ServerFailure('not_signed_in');
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final name = userDoc.data()?['name'] as String? ?? '';
      await _orders.doc(orderId).collection('notes').add({
        'text': text,
        'byUid': uid,
        'byName': name,
        'at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
