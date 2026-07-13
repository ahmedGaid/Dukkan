part of 'audit_log_bloc.dart';

sealed class AuditLogEvent extends Equatable {
  const AuditLogEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads the first page for the current filter.
class AuditStarted extends AuditLogEvent {
  const AuditStarted();
}

/// Re-runs the first-page load after an error.
class AuditRetryRequested extends AuditLogEvent {
  const AuditRetryRequested();
}

/// A filter control changed — replaces the filter and reloads from the top.
class AuditFilterChanged extends AuditLogEvent {
  const AuditFilterChanged(this.filter);

  final AuditFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Appends the next page (cursor = the last loaded entry's timestamp).
class AuditLoadMoreRequested extends AuditLogEvent {
  const AuditLoadMoreRequested();
}
