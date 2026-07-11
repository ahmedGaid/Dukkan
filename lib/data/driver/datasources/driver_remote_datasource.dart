import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/driver_model.dart';

class DriverRemoteDataSource {
  DriverRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

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
}
