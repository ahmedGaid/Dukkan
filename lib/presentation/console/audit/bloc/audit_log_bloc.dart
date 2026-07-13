import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/audit/entities/audit_filter.dart';
import '../../../../domain/audit/usecases/get_audit_entries.dart';

part 'audit_log_event.dart';
part 'audit_log_state.dart';

/// Drives the console audit viewer: a first page on open, filter changes that
/// reload from the top, and cursor pagination that appends. The next-page
/// cursor is the last loaded entry's `createdAt` (value-based — see
/// `AuditRemoteDataSource`), so no Firestore type crosses into presentation.
class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  AuditLogBloc({required GetAuditEntries getAuditEntries})
      : _getAuditEntries = getAuditEntries,
        super(const AuditLogState()) {
    on<AuditStarted>(_onReload);
    on<AuditRetryRequested>(_onReload);
    on<AuditFilterChanged>(_onFilterChanged);
    on<AuditLoadMoreRequested>(_onLoadMore);
  }

  final GetAuditEntries _getAuditEntries;

  Future<void> _onFilterChanged(
    AuditFilterChanged event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter));
    await _load(emit);
  }

  Future<void> _onReload(
    AuditLogEvent event,
    Emitter<AuditLogState> emit,
  ) =>
      _load(emit);

  /// Fresh load of page one for the current filter (open / retry / filter
  /// change). One loading-to-loaded emit, no flicker.
  Future<void> _load(Emitter<AuditLogState> emit) async {
    emit(state.copyWith(status: AuditLogStatus.loading));
    try {
      final page = await _getAuditEntries(filter: state.filter);
      emit(state.copyWith(
        status: AuditLogStatus.loaded,
        entries: page.entries,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: AuditLogStatus.error));
    }
  }

  Future<void> _onLoadMore(
    AuditLoadMoreRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    // Ignore while not on a loaded page, already fetching, or at the end.
    if (state.status != AuditLogStatus.loaded ||
        state.loadingMore ||
        !state.hasMore ||
        state.entries.isEmpty) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final cursor = state.entries.last.createdAt.toUtc().toIso8601String();
      final page = await _getAuditEntries(
        filter: state.filter,
        afterCreatedAt: cursor,
      );
      emit(state.copyWith(
        entries: [...state.entries, ...page.entries],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      // Keep the entries already shown; just stop the footer spinner. The next
      // scroll/tap can retry the page.
      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }
}
