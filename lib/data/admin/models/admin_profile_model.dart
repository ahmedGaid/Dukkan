import '../../../domain/admin/entities/admin_profile.dart';
import '../../../domain/admin/entities/staff_role.dart';

class AdminProfileModel extends AdminProfile {
  const AdminProfileModel({
    required super.uid,
    required super.role,
    required super.permissions,
    required super.isActive,
    required super.rank,
  });

  /// Parses an `/admins/{uid}` doc. Fail-closed: any missing field defaults to
  /// the least-privileged value, and an unrecognized `role` string forces
  /// `isActive: false` (a doc we can't fully trust is never treated as active).
  factory AdminProfileModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final roleWire = data['role'] as String?;
    final roleKnown =
        roleWire != null && StaffRole.values.any((r) => r.wire == roleWire);
    final permissions = (data['permissions'] as List?)
            ?.map((e) => e as String)
            .toSet() ??
        <String>{};

    return AdminProfileModel(
      uid: uid,
      role: roleKnown ? StaffRole.fromWire(roleWire) : StaffRole.support,
      permissions: permissions,
      isActive: roleKnown && (data['isActive'] as bool? ?? false),
      rank: (data['rank'] as num?)?.toInt() ?? 0,
    );
  }
}
