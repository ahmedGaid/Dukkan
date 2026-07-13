part of 'audit_log_bloc.dart';

enum AuditLogStatus { loading, loaded, error }

class AuditLogState extends Equatable {
  const AuditLogState({
    this.status = AuditLogStatus.loading,
    this.entries = const [],
    this.filter = const AuditFilter(),
    this.hasMore = false,
    this.loadingMore = false,
  });

  final AuditLogStatus status;
  final List<AuditEntry> entries;
  final AuditFilter filter;

  /// Another page probably exists (last fetch filled the page).
  final bool hasMore;

  /// A `loadMore` fetch is in flight (footer spinner; list stays put).
  final bool loadingMore;

  AuditLogState copyWith({
    AuditLogStatus? status,
    List<AuditEntry>? entries,
    AuditFilter? filter,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return AuditLogState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [status, entries, filter, hasMore, loadingMore];
}
