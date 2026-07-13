part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads the first page for the current filter.
class UsersStarted extends UsersEvent {
  const UsersStarted();
}

/// Re-runs the first-page load after an error.
class UsersRetryRequested extends UsersEvent {
  const UsersRetryRequested();
}

/// Role and/or status filter chip changed — replaces both and reloads.
class UsersFilterChanged extends UsersEvent {
  const UsersFilterChanged({this.role, this.status});

  final String? role;
  final String? status;

  @override
  List<Object?> get props => [role, status];
}

/// Appends the next page (cursor = the last loaded row's uid).
class UsersLoadMoreRequested extends UsersEvent {
  const UsersLoadMoreRequested();
}

/// The search field was submitted — exact email/phone hits Firestore
/// directly; anything else filters the page already in memory.
class UsersSearchSubmitted extends UsersEvent {
  const UsersSearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The search field was cleared — back to the normal paginated list.
class UsersSearchCleared extends UsersEvent {
  const UsersSearchCleared();
}

/// A row's selection checkbox was tapped (bulk actions).
class UserSelectionToggled extends UsersEvent {
  const UserSelectionToggled(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class UsersSelectionCleared extends UsersEvent {
  const UsersSelectionCleared();
}

/// Bulk suspend/unsuspend/ban over the current selection.
class UsersBulkSetDisabledRequested extends UsersEvent {
  const UsersBulkSetDisabledRequested(this.status);

  final String status;

  @override
  List<Object?> get props => [status];
}
