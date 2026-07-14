import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../areas/models/area_model.dart';

/// Firestore-direct reads/writes of `/areas` for the console (FC9). Unlike
/// the read-only `AreasRemoteDataSource`, this returns every area
/// (deactivated included) and exposes the console's mutations; writes rely
/// on the `geo.edit` rules branch, never a Worker route.
class AdminGeoRemoteDataSource {
  AdminGeoRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _areas =>
      _firestore.collection('areas');

  Future<List<AreaModel>> getAllAreas() async {
    try {
      final snap = await _areas.orderBy('sort').get();
      return snap.docs
          .map((d) => AreaModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> createArea(Map<String, dynamic> fields) async {
    try {
      await _areas.add(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchFields(String areaId, Map<String, dynamic> fields) async {
    try {
      await _areas.doc(areaId).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteArea(String areaId) async {
    try {
      await _areas.doc(areaId).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<int> countOrdersInArea(String areaId) async {
    try {
      final agg = await _firestore
          .collection('orders')
          .where('deliveryAddress.areaId', isEqualTo: areaId)
          .count()
          .get();
      return agg.count ?? 0;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
