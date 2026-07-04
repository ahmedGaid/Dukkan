import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/entities/user_role.dart';

/// Firestore <-> [AppUser] mapping. The `uid` is the `/users` doc id; `email`
/// is denormalized onto the doc so owner/customer lists don't need an Auth
/// lookup. `createdAt` is written server-side only (not read back into the
/// entity — the domain doesn't need it yet).
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.phone,
  });

  factory AppUserModel.fromFirestore(
    String uid,
    Map<String, dynamic> data, {
    String? authEmail,
  }) {
    return AppUserModel(
      uid: uid,
      email: (data['email'] as String?) ?? authEmail ?? '',
      name: (data['name'] as String?) ?? '',
      role: UserRole.fromWire((data['role'] as String?) ?? 'customer'),
      phone: data['phone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role.wire,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}
