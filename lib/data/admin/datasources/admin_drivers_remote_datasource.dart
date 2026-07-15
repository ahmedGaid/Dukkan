import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/admin/entities/driver_performance.dart';
import '../../driver/models/driver_model.dart';
import '../../order/models/order_model.dart';

/// Firestore-direct reads/writes of `/drivers` for the console, plus the
/// `/orders` queries the detail page's performance card and assigned-orders
/// list need. Unlike `AdminUsersRemoteDataSource`, no permission-gated read
/// is needed — `/drivers` read is `isSignedIn()`; writes here rely on the
/// `drivers.manage` rules branch (see `firestore.rules`).
class AdminDriversRemoteDataSource {
  AdminDriversRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<List<DriverModel>> getAllDrivers() async {
    try {
      final snap = await _drivers.orderBy('name').get();
      return snap.docs
          .map((d) => DriverModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<DriverModel?> getDriverById(String uid) async {
    try {
      final doc = await _drivers.doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      return DriverModel.fromFirestore(doc.id, data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _drivers.doc(uid).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<DriverPerformance> getPerformance(String uid) async {
    try {
      final now = DateTime.now();
      final monthStart = Timestamp.fromDate(DateTime(now.year, now.month));
      final delivered = _orders.where('driverUid', isEqualTo: uid).where('status',
          isEqualTo: 'delivered');

      final results = await Future.wait([
        delivered.count().get(),
        delivered.where('createdAt', isGreaterThanOrEqualTo: monthStart).count().get(),
      ]);

      return DriverPerformance(
        deliveredTotal: results[0].count ?? 0,
        deliveredThisMonth: results[1].count ?? 0,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<List<OrderModel>> getAssignedOrders(String uid) async {
    try {
      final snap = await _orders
          .where('driverUid', isEqualTo: uid)
          .where('status', whereIn: ['preparing', 'outForDelivery'])
          .get();
      return snap.docs
          .map((d) => OrderModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
