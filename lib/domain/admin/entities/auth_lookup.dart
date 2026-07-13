import 'package:equatable/equatable.dart';

/// Firebase Auth-side facts for one account, fetched via the Worker's
/// `/admin/users/lookup` (Identity Toolkit `accounts:lookup`) — the console
/// user detail page's "auth card". Not stored anywhere; always a live read.
class AuthLookup extends Equatable {
  const AuthLookup({
    required this.email,
    required this.emailVerified,
    required this.disabled,
    this.lastLoginAt,
    this.createdAt,
  });

  final String? email;
  final bool emailVerified;
  final bool disabled;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [email, emailVerified, disabled, lastLoginAt, createdAt];
}
