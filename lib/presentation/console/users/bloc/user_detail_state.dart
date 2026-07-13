part of 'user_detail_bloc.dart';

enum UserDetailStatus { loading, loaded, error }

class UserDetailState extends Equatable {
  const UserDetailState({
    required this.user,
    this.status = UserDetailStatus.loading,
    this.authLookup,
    this.staffProfile,
    this.actionBusy = false,
    this.actionError,
  });

  final UserDetailStatus status;
  final ManagedUser user;
  final AuthLookup? authLookup;

  /// Null = the target is not staff.
  final AdminProfile? staffProfile;

  /// True while any mutation (disable/role/email/delete/restore/reset/admin
  /// set/remove) is in flight — the page disables its action buttons.
  final bool actionBusy;

  /// The last mutation's technical failure code, or null if it succeeded /
  /// none has run yet. The page's `BlocListener` watches `actionBusy`
  /// transitioning true → false and reads this to decide the snackbar.
  final String? actionError;

  static const _unset = Object();

  UserDetailState copyWith({
    UserDetailStatus? status,
    ManagedUser? user,
    Object? authLookup = _unset,
    Object? staffProfile = _unset,
    bool? actionBusy,
    Object? actionError = _unset,
  }) {
    return UserDetailState(
      user: user ?? this.user,
      status: status ?? this.status,
      authLookup: authLookup == _unset ? this.authLookup : authLookup as AuthLookup?,
      staffProfile: staffProfile == _unset ? this.staffProfile : staffProfile as AdminProfile?,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError == _unset ? this.actionError : actionError as String?,
    );
  }

  @override
  List<Object?> get props => [status, user, authLookup, staffProfile, actionBusy, actionError];
}
