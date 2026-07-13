import 'package:equatable/equatable.dart';

import '../../auth/entities/user_role.dart';

/// A `/users/{uid}` doc as seen by the Founder Console (Session 6) — a richer
/// read model than [AppUser], which only carries what the signed-in user's own
/// session needs. Adds the moderation fields ([status], soft-delete) the
/// console's user management screens read and write via the Worker.
class ManagedUser extends Equatable {
  const ManagedUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.status = 'active',
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  /// `active` | `suspended` | `banned`. Defaults to `active` for pre-Session-6
  /// docs that predate the field.
  final String status;

  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        role,
        phone,
        status,
        deleted,
        deletedAt,
        deletedBy,
        createdAt,
      ];
}
