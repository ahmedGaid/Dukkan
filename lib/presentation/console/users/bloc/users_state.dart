part of 'users_bloc.dart';

enum UsersStatus { loading, loaded, error }

class UsersState extends Equatable {
  const UsersState({
    this.status = UsersStatus.loading,
    this.users = const [],
    this.role,
    this.statusFilter,
    this.hasMore = false,
    this.loadingMore = false,
    this.searching = false,
    this.searchResults,
    this.selected = const {},
    this.bulkBusy = false,
    this.bulkDone = 0,
    this.bulkTotal = 0,
    this.bulkSucceeded = 0,
  });

  final UsersStatus status;
  final List<ManagedUser> users;
  final String? role;
  final String? statusFilter;
  final bool hasMore;
  final bool loadingMore;

  final bool searching;

  /// Null = showing the normal paginated [users] list; non-null = showing
  /// these exact/local-filter results instead (no pagination over a search).
  final List<ManagedUser>? searchResults;

  final Set<String> selected;
  final bool bulkBusy;
  final int bulkDone;
  final int bulkTotal;
  final int bulkSucceeded;

  /// What the list widget should actually render.
  List<ManagedUser> get visibleUsers => searchResults ?? users;

  static const _unset = Object();

  UsersState copyWith({
    UsersStatus? status,
    List<ManagedUser>? users,
    Object? role = _unset,
    Object? statusFilter = _unset,
    bool? hasMore,
    bool? loadingMore,
    bool? searching,
    Object? searchResults = _unset,
    Set<String>? selected,
    bool? bulkBusy,
    int? bulkDone,
    int? bulkTotal,
    int? bulkSucceeded,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      role: role == _unset ? this.role : role as String?,
      statusFilter: statusFilter == _unset ? this.statusFilter : statusFilter as String?,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      searching: searching ?? this.searching,
      searchResults: searchResults == _unset
          ? this.searchResults
          : searchResults as List<ManagedUser>?,
      selected: selected ?? this.selected,
      bulkBusy: bulkBusy ?? this.bulkBusy,
      bulkDone: bulkDone ?? this.bulkDone,
      bulkTotal: bulkTotal ?? this.bulkTotal,
      bulkSucceeded: bulkSucceeded ?? this.bulkSucceeded,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        role,
        statusFilter,
        hasMore,
        loadingMore,
        searching,
        searchResults,
        selected,
        bulkBusy,
        bulkDone,
        bulkTotal,
        bulkSucceeded,
      ];
}
