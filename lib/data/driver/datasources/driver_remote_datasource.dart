import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/driver_model.dart';

class DriverRemoteDataSource {
  DriverRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<void> createDriverProfile({
    required String uid,
    required String name,
    String? phone,
  }) {
    final model = DriverModel.newProfile(uid: uid, name: name, phone: phone);
    return _drivers.doc(uid).set({
      ...model.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DriverModel?> getDriver(String uid) async {
    final data = (await _drivers.doc(uid).get()).data();
    if (data == null) return null;
    return DriverModel.fromFirestore(uid, data);
  }

  Stream<DriverModel?> watchDriver(String uid) {
    return _drivers.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : DriverModel.fromFirestore(uid, data);
    });
  }

  Future<void> setOnline(String uid, bool isOnline) =>
      _drivers.doc(uid).update({'isOnline': isOnline});

  Future<List<DriverModel>> availableDrivers(String areaId) async {
    final snap = await _drivers
        .where('areaIds', arrayContains: areaId)
        .where('isOnline', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .get();
    return snap.docs
        .map((doc) => DriverModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// The assignment transaction (M9). Re-reads both docs inside the
  /// transaction so two owners racing for the same driver's last slot
  /// resolve safely — the second retry sees the bumped `activeOrdersCount`
  /// and fails clean on capacity rather than double-booking.
  Future<void> assignDriver({
    required String orderId,
    required String driverUid,
  }) async {
    try {
      final driverRef = _drivers.doc(driverUid);
      final orderRef = _orders.doc(orderId);
      await _firestore.runTransaction((txn) async {
        final driverSnap = await txn.get(driverRef);
        final orderSnap = await txn.get(orderRef);
        final driverData = driverSnap.data();
        final orderData = orderSnap.data();
        if (driverData == null) {
          throw const DriverUnavailable(DriverUnavailableReason.offline);
        }

        final active = (driverData['activeOrdersCount'] as num?)?.toInt() ?? 0;
        final max = (driverData['maxActiveOrders'] as num?)?.toInt() ?? 0;
        final areas = List<String>.from(driverData['areaIds'] as List? ?? const []);
        final orderArea =
            (orderData?['deliveryAddress'] as Map?)?['areaId'] as String?;
        final status = orderData?['status'] as String?;

        if (driverData['isSuspended'] == true) {
          throw const DriverUnavailable(DriverUnavailableReason.suspended);
        }
        if (driverData['isOnline'] != true) {
          throw const DriverUnavailable(DriverUnavailableReason.offline);
        }
        if (active >= max) {
          throw const DriverUnavailable(DriverUnavailableReason.capacity);
        }
        if (orderArea == null || !areas.contains(orderArea)) {
          throw const DriverUnavailable(DriverUnavailableReason.area);
        }
        if (status != 'accepted' && status != 'preparing') {
          throw const DriverUnavailable(DriverUnavailableReason.status);
        }
        if (orderData?['driverUid'] != null) {
          throw const DriverUnavailable(DriverUnavailableReason.taken);
        }

        txn.update(driverRef, {'activeOrdersCount': active + 1});
        txn.update(orderRef, {
          'driverUid': driverUid,
          'driverName': driverData['name'],
          'driverPhone': driverData['phone'],
          'assignedAt': DateTime.now().toIso8601String(),
        });
      });
    } on DriverUnavailable {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
