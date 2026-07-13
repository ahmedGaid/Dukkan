import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/usecases/get_user_by_email.dart';
import '../../../../domain/admin/usecases/get_user_by_phone.dart';
import '../../../../domain/admin/usecases/get_users.dart';
import '../../../../domain/admin/usecases/set_user_disabled.dart';

part 'users_event.dart';
part 'users_state.dart';

/// Drives the console user list (`/console/users`): a paginated, filterable
/// list plus an exact search (email/phone hit the Worker-readable `/users`
/// collection directly; anything else filters the page already loaded — see
/// the search field's hint text) and bulk suspend/unsuspend over a
/// multi-selection. Mirrors `AuditLogBloc`'s load/filter/paginate shape.
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({
    required GetUsers getUsers,
    required GetUserByEmail getUserByEmail,
    required GetUserByPhone getUserByPhone,
    required SetUserDisabled setUserDisabled,
  })  : _getUsers = getUsers,
        _getUserByEmail = getUserByEmail,
        _getUserByPhone = getUserByPhone,
        _setUserDisabled = setUserDisabled,
        super(const UsersState()) {
    on<UsersStarted>(_onReload);
    on<UsersRetryRequested>(_onReload);
    on<UsersFilterChanged>(_onFilterChanged);
    on<UsersLoadMoreRequested>(_onLoadMore);
    on<UsersSearchSubmitted>(_onSearchSubmitted);
    on<UsersSearchCleared>((event, emit) => emit(state.copyWith(searchResults: null)));
    on<UserSelectionToggled>(_onSelectionToggled);
    on<UsersSelectionCleared>((event, emit) => emit(state.copyWith(selected: const {})));
    on<UsersBulkSetDisabledRequested>(_onBulkSetDisabled);
  }

  final GetUsers _getUsers;
  final GetUserByEmail _getUserByEmail;
  final GetUserByPhone _getUserByPhone;
  final SetUserDisabled _setUserDisabled;

  Future<void> _onReload(UsersEvent event, Emitter<UsersState> emit) => _load(emit);

  Future<void> _onFilterChanged(UsersFilterChanged event, Emitter<UsersState> emit) async {
    emit(state.copyWith(role: event.role, statusFilter: event.status, searchResults: null));
    await _load(emit);
  }

  Future<void> _load(Emitter<UsersState> emit) async {
    emit(state.copyWith(status: UsersStatus.loading));
    try {
      final page = await _getUsers(role: state.role, status: state.statusFilter);
      emit(state.copyWith(
        status: UsersStatus.loaded,
        users: page.users,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: UsersStatus.error));
    }
  }

  Future<void> _onLoadMore(UsersLoadMoreRequested event, Emitter<UsersState> emit) async {
    if (state.status != UsersStatus.loaded ||
        state.loadingMore ||
        !state.hasMore ||
        state.users.isEmpty) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getUsers(
        role: state.role,
        status: state.statusFilter,
        cursor: state.users.last.uid,
      );
      emit(state.copyWith(
        users: [...state.users, ...page.users],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }

  static final _phonePattern = RegExp(r'^[0-9+ ]{4,}$');

  Future<void> _onSearchSubmitted(UsersSearchSubmitted event, Emitter<UsersState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: null));
      return;
    }
    emit(state.copyWith(searching: true));
    try {
      if (query.contains('@')) {
        final user = await _getUserByEmail(query);
        emit(state.copyWith(searching: false, searchResults: user == null ? const [] : [user]));
      } else if (_phonePattern.hasMatch(query)) {
        final user = await _getUserByPhone(query);
        emit(state.copyWith(searching: false, searchResults: user == null ? const [] : [user]));
      } else {
        final lower = query.toLowerCase();
        final matches = state.users.where((u) => u.name.toLowerCase().contains(lower)).toList();
        emit(state.copyWith(searching: false, searchResults: matches));
      }
    } catch (_) {
      emit(state.copyWith(searching: false, searchResults: const []));
    }
  }

  void _onSelectionToggled(UserSelectionToggled event, Emitter<UsersState> emit) {
    final next = Set<String>.from(state.selected);
    if (!next.add(event.uid)) next.remove(event.uid);
    emit(state.copyWith(selected: next));
  }

  Future<void> _onBulkSetDisabled(
    UsersBulkSetDisabledRequested event,
    Emitter<UsersState> emit,
  ) async {
    final uids = state.selected.toList(growable: false);
    if (uids.isEmpty) return;
    emit(state.copyWith(
      bulkBusy: true,
      bulkDone: 0,
      bulkTotal: uids.length,
      bulkSucceeded: 0,
    ));
    var done = 0;
    var succeeded = 0;
    for (final uid in uids) {
      try {
        await _setUserDisabled(uid: uid, status: event.status);
        succeeded++;
      } catch (_) {
        // Keep going — one failure shouldn't abort the rest of the batch;
        // `bulkSucceeded` vs `bulkTotal` in the final summary shows the gap.
      }
      done++;
      emit(state.copyWith(bulkDone: done, bulkSucceeded: succeeded));
    }
    emit(state.copyWith(bulkBusy: false, selected: const {}));
    await _load(emit);
  }
}
