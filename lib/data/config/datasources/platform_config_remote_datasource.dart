import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/platform_config_model.dart';

class PlatformConfigRemoteDataSource {
  PlatformConfigRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<PlatformConfigModel> getConfig() async {
    try {
      final snap =
          await _firestore.collection('config').doc('platform').get();
      final data = snap.data();
      if (data == null) {
        throw const ServerFailure('Platform config not seeded');
      }
      return PlatformConfigModel.fromFirestore(data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
