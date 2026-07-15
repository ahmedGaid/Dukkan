import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/feature_flags_model.dart';

class FlagsRemoteDataSource {
  FlagsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<FeatureFlagsModel> getFlags() async {
    try {
      final snap = await _firestore.collection('config').doc('flags').get();
      final data = snap.data();
      if (data == null) {
        throw const ServerFailure('Feature flags not seeded');
      }
      return FeatureFlagsModel.fromFirestore(data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
