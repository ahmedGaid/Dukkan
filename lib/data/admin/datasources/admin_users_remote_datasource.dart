import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/admin/entities/users_page.dart';
import '../models/managed_user_model.dart';

/// Firestore-direct reads of `/users` for the console (rules allow it via
/// `hasPerm('users.read')`). Ordered by document id — never `createdAt`,
/// whose type can differ between older client-created docs and newer
/// Worker-created ones — so pagination never depends on a field that might
/// be absent or mixed-type on legacy docs.
class AdminUsersRemoteDataSource {
  AdminUsersRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const pageSize = 25;

  Future<UsersPage> getUsers({String? role, String? status, String? cursor}) async {
    try {
      Query<Map<String, dynamic>> q = _firestore.collection('users');
      if (role != null) q = q.where('role', isEqualTo: role);
      if (status != null) q = q.where('status', isEqualTo: status);
      q = q.orderBy(FieldPath.documentId);
      if (cursor != null) q = q.startAfter([cursor]);
      q = q.limit(pageSize);

      final snap = await q.get();
      final users = snap.docs
          .map((d) => ManagedUserModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
      return UsersPage(users: users, hasMore: users.length == pageSize);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<ManagedUserModel?> getByEmail(String email) => _getByField('email', email);

  Future<ManagedUserModel?> getByPhone(String phone) => _getByField('phone', phone);

  Future<ManagedUserModel?> _getByField(String field, String value) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return ManagedUserModel.fromFirestore(snap.docs.first.id, snap.docs.first.data());
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
