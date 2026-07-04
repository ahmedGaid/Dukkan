import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// A signed-in Dukkan user. Identity comes from Firebase Auth (`uid`, `email`);
/// profile (`name`, `phone`, `role`) lives on the `/users/{uid}` Firestore doc.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? phone;

  @override
  List<Object?> get props => [uid, email, name, role, phone];
}
