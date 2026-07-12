import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/admin_profile_model.dart';

/// One read of `/admins/{uid}`. Returns null when the doc is missing (the
/// account is not staff); throws [ServerFailure] only on an actual backend
/// error, which the repository/BLoC treats as "not staff" so login is never
/// blocked.
class AdminRemoteDataSource {
  AdminRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<AdminProfileModel?> get(String uid) async {
    try {
      final snap = await _firestore.collection('admins').doc(uid).get();
      final data = snap.data();
      if (data == null) return null;
      return AdminProfileModel.fromFirestore(uid, data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
