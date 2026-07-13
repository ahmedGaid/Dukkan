import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/entities/admin_profile.dart';
import '../../../../domain/admin/entities/auth_lookup.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/usecases/change_user_email.dart';
import '../../../../domain/admin/usecases/get_staff_profile_for_uid.dart';
import '../../../../domain/admin/usecases/get_user_by_email.dart';
import '../../../../domain/admin/usecases/lookup_user_auth.dart';
import '../../../../domain/admin/usecases/remove_admin.dart';
import '../../../../domain/admin/usecases/restore_user.dart';
import '../../../../domain/admin/usecases/set_admin.dart';
import '../../../../domain/admin/usecases/set_user_disabled.dart';
import '../../../../domain/admin/usecases/set_user_persona_role.dart';
import '../../../../domain/admin/usecases/soft_delete_user.dart';
import '../../../../domain/auth/usecases/send_password_reset.dart';

part 'user_detail_event.dart';
part 'user_detail_state.dart';

/// Drives the console user detail page (`/console/users/:uid`). Every
/// mutation goes through a Worker `/admin/*` endpoint (never a direct
/// Firestore/Auth write from here); after each one succeeds this reloads the
/// three panels (`/users` doc via exact-email lookup, Auth-side facts, staff
/// profile) so the page always shows the post-mutation truth, not an
/// optimistic guess.
class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  UserDetailBloc({
    required ManagedUser seed,
    required LookupUserAuth lookupUserAuth,
    required GetStaffProfileForUid getStaffProfileForUid,
    required GetUserByEmail getUserByEmail,
    required SetUserDisabled setUserDisabled,
    required SetUserPersonaRole setUserPersonaRole,
    required ChangeUserEmail changeUserEmail,
    required SoftDeleteUser softDeleteUser,
    required RestoreUser restoreUser,
    required SendPasswordReset sendPasswordReset,
    required SetAdmin setAdmin,
    required RemoveAdmin removeAdmin,
  })  : _lookupUserAuth = lookupUserAuth,
        _getStaffProfileForUid = getStaffProfileForUid,
        _getUserByEmail = getUserByEmail,
        _setUserDisabled = setUserDisabled,
        _setUserPersonaRole = setUserPersonaRole,
        _changeUserEmail = changeUserEmail,
        _softDeleteUser = softDeleteUser,
        _restoreUser = restoreUser,
        _sendPasswordReset = sendPasswordReset,
        _setAdmin = setAdmin,
        _removeAdmin = removeAdmin,
        super(UserDetailState(user: seed)) {
    on<UserDetailStarted>(_onStarted);
    on<UserDetailRetryRequested>(_onStarted);
    on<UserDetailSetDisabledRequested>(
      (e, emit) => _runAction(emit, () => _setUserDisabled(uid: e.uid, status: e.status)),
    );
    on<UserDetailSetPersonaRoleRequested>(
      (e, emit) => _runAction(emit, () => _setUserPersonaRole(uid: e.uid, role: e.role)),
    );
    on<UserDetailChangeEmailRequested>(
      (e, emit) => _runAction(emit, () => _changeUserEmail(uid: e.uid, email: e.email)),
    );
    on<UserDetailSoftDeleteRequested>(
      (e, emit) => _runAction(emit, () => _softDeleteUser(e.uid)),
    );
    on<UserDetailRestoreRequested>(
      (e, emit) => _runAction(emit, () => _restoreUser(e.uid)),
    );
    on<UserDetailSendPasswordResetRequested>(_onSendPasswordReset);
    on<UserDetailSetAdminRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setAdmin(uid: e.uid, role: e.role, extraPermissions: e.extraPermissions),
        refreshStaff: true,
      ),
    );
    on<UserDetailRemoveAdminRequested>(
      (e, emit) => _runAction(emit, () => _removeAdmin(e.uid), refreshStaff: true),
    );
  }

  final LookupUserAuth _lookupUserAuth;
  final GetStaffProfileForUid _getStaffProfileForUid;
  final GetUserByEmail _getUserByEmail;
  final SetUserDisabled _setUserDisabled;
  final SetUserPersonaRole _setUserPersonaRole;
  final ChangeUserEmail _changeUserEmail;
  final SoftDeleteUser _softDeleteUser;
  final RestoreUser _restoreUser;
  final SendPasswordReset _sendPasswordReset;
  final SetAdmin _setAdmin;
  final RemoveAdmin _removeAdmin;

  Future<void> _onStarted(UserDetailEvent event, Emitter<UserDetailState> emit) async {
    emit(state.copyWith(status: UserDetailStatus.loading, actionError: null));
    try {
      final authFuture = _lookupUserAuth(state.user.uid);
      final staffFuture = _getStaffProfileForUid(state.user.uid);
      final auth = await authFuture;
      final staff = await staffFuture;
      emit(state.copyWith(
        status: UserDetailStatus.loaded,
        authLookup: auth,
        staffProfile: staff,
      ));
    } catch (_) {
      emit(state.copyWith(status: UserDetailStatus.error));
    }
  }

  /// Runs one mutation; on success reloads the user (via exact-email lookup —
  /// there is no get-by-uid on `AdminUsersRepository`, only exact email/phone)
  /// plus the Auth/staff panels so the page reflects the real post-mutation
  /// state rather than an optimistic guess. On failure, surfaces
  /// [actionError] for a snackbar; the page's data stays as-is.
  Future<void> _runAction(
    Emitter<UserDetailState> emit,
    Future<void> Function() action, {
    bool refreshStaff = false,
  }) async {
    emit(state.copyWith(actionBusy: true, actionError: null));
    try {
      await action();
      final refreshedUser = await _getUserByEmail(state.user.email);
      final auth = await _lookupUserAuth(state.user.uid);
      final staff =
          refreshStaff ? await _getStaffProfileForUid(state.user.uid) : state.staffProfile;
      emit(state.copyWith(
        actionBusy: false,
        user: refreshedUser ?? state.user,
        authLookup: auth,
        staffProfile: staff,
      ));
    } catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: e.toString()));
    }
  }

  Future<void> _onSendPasswordReset(
    UserDetailSendPasswordResetRequested event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: null));
    try {
      await _sendPasswordReset(state.user.email);
      emit(state.copyWith(actionBusy: false));
    } catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: e.toString()));
    }
  }
}
