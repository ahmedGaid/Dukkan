import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/area_model.dart';

class AreasRemoteDataSource {
  AreasRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// One read of the whole (small, fixed) list, sorted by `sort`.
  Future<List<AreaModel>> getAreas() async {
    final snap = await _firestore.collection('areas').orderBy('sort').get();
    return snap.docs
        .map((doc) => AreaModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
