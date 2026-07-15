import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';

class AdminSettingsRemoteDataSource {
  AdminSettingsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> patchConfig(Map<String, dynamic> fields) async {
    try {
      await _firestore.collection('config').doc('platform').update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> setFlag(String key, bool value) async {
    try {
      await _firestore
          .collection('config')
          .doc('flags')
          .update({'flags.$key': value});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteFlag(String key) async {
    try {
      await _firestore
          .collection('config')
          .doc('flags')
          .update({'flags.$key': FieldValue.delete()});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
