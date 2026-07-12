import 'package:equatable/equatable.dart';

import 'permissions.dart';
import 'staff_role.dart';

/// A signed-in account's back-office identity (Founder Console RBAC). Present
/// only for staff — a null [AdminProfile] means "not staff". [permissions] is
/// already flattened (role permissions + per-admin extras, denormalized onto
/// the `/admins` doc by the Worker), so a check is one in-memory lookup.
class AdminProfile extends Equatable {
  const AdminProfile({
    required this.uid,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.rank,
  });

  final String uid;
  final StaffRole role;
  final Set<String> permissions; // flat, already denormalized (role + extras)
  final bool isActive;
  final int rank;

  /// Whether this account may perform [perm]. An inactive admin can do
  /// nothing; the founder wildcard ([Permissions.all]) grants everything.
  bool can(String perm) =>
      isActive &&
      (permissions.contains(perm) || permissions.contains(Permissions.all));

  @override
  List<Object?> get props => [uid, role, permissions, isActive, rank];
}
