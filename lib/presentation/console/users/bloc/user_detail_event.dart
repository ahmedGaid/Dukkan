part of 'user_detail_bloc.dart';

sealed class UserDetailEvent extends Equatable {
  const UserDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads the Auth-side and staff panels.
class UserDetailStarted extends UserDetailEvent {
  const UserDetailStarted();
}

class UserDetailRetryRequested extends UserDetailEvent {
  const UserDetailRetryRequested();
}

/// `active` | `suspended` | `banned`.
class UserDetailSetDisabledRequested extends UserDetailEvent {
  const UserDetailSetDisabledRequested({required this.uid, required this.status});

  final String uid;
  final String status;

  @override
  List<Object?> get props => [uid, status];
}

/// `customer` | `owner` | `courier` — persona only.
class UserDetailSetPersonaRoleRequested extends UserDetailEvent {
  const UserDetailSetPersonaRoleRequested({required this.uid, required this.role});

  final String uid;
  final String role;

  @override
  List<Object?> get props => [uid, role];
}

class UserDetailChangeEmailRequested extends UserDetailEvent {
  const UserDetailChangeEmailRequested({required this.uid, required this.email});

  final String uid;
  final String email;

  @override
  List<Object?> get props => [uid, email];
}

class UserDetailSoftDeleteRequested extends UserDetailEvent {
  const UserDetailSoftDeleteRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class UserDetailRestoreRequested extends UserDetailEvent {
  const UserDetailRestoreRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Client-SDK `sendPasswordResetEmail` — NOT a Worker endpoint (spec: "not an
/// admin endpoint"), so no `uid` is needed, just the account's email.
class UserDetailSendPasswordResetRequested extends UserDetailEvent {
  const UserDetailSendPasswordResetRequested();
}

/// Creates/updates the target's `/admins` doc (rank-guarded server-side).
class UserDetailSetAdminRequested extends UserDetailEvent {
  const UserDetailSetAdminRequested({
    required this.uid,
    required this.role,
    this.extraPermissions = const [],
  });

  final String uid;
  final String role;
  final List<String> extraPermissions;

  @override
  List<Object?> get props => [uid, role, extraPermissions];
}

class UserDetailRemoveAdminRequested extends UserDetailEvent {
  const UserDetailRemoveAdminRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}
