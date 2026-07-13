import '../../../domain/admin/entities/auth_lookup.dart';

/// Parses the Worker's `/admin/users/lookup` response (Identity Toolkit
/// `accounts:lookup` fields, passed through verbatim). `lastLoginAt`/
/// `createdAt` are epoch-millisecond strings — Identity Toolkit's convention,
/// not Firestore's — so they're parsed by hand rather than as a Timestamp.
class AuthLookupModel extends AuthLookup {
  const AuthLookupModel({
    required super.email,
    required super.emailVerified,
    required super.disabled,
    super.lastLoginAt,
    super.createdAt,
  });

  factory AuthLookupModel.fromJson(Map<String, dynamic> json) {
    return AuthLookupModel(
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      lastLoginAt: _parseEpochMs(json['lastLoginAt']),
      createdAt: _parseEpochMs(json['createdAt']),
    );
  }

  static DateTime? _parseEpochMs(Object? value) {
    if (value == null) return null;
    final ms = int.tryParse(value.toString());
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
