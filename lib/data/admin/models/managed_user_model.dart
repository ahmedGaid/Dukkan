import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/admin/entities/managed_user.dart';
import '../../../domain/auth/entities/user_role.dart';

/// Parses a `/users/{uid}` doc for the console's user management screens.
/// `createdAt`/`deletedAt` are always a real Firestore `Timestamp` — both the
/// client (`FieldValue.serverTimestamp()`) and the Worker (`fsTimestamp` in
/// `firebase.js`) write the same wire type, so there is no string-vs-Timestamp
/// split to handle here.
class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
    super.status,
    super.deleted,
    super.deletedAt,
    super.deletedBy,
    super.createdAt,
  });

  factory ManagedUserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return ManagedUserModel(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: UserRole.fromWire((data['role'] as String?) ?? 'customer'),
      phone: data['phone'] as String?,
      status: (data['status'] as String?) ?? 'active',
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
