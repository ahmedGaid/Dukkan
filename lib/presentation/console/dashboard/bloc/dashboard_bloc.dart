import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/audit/entities/audit_filter.dart';
import '../../../../domain/audit/usecases/get_audit_entries.dart';
import '../../../../domain/dashboard/entities/dashboard_summary.dart';
import '../../../../domain/dashboard/usecases/get_dashboard_summary.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Drives the console dashboard (FC5): the aggregate snapshot and the recent-
/// activity strip load together in parallel, then emit once (no double-loading
/// flicker — Shoppy lesson). A 60-second timer refreshes silently; first open
/// and pull-to-refresh show the skeleton.
///
/// The viewer's read permissions arrive on [DashboardStarted] (resolved from
/// the AuthBloc in the page) and gate the two permission-sensitive reads — the
/// `/users` count and the `/auditLogs` strip — so a moderator or support agent
/// opening the (any-staff) dashboard never trips a permission-denied.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardSummary getDashboardSummary,
    required GetAuditEntries getAuditEntries,
  })  : _getSummary = getDashboardSummary,
        _getAuditEntries = getAuditEntries,
        super(const DashboardState()) {
    on<DashboardStarted>(_onStart);
    on<DashboardRefreshRequested>((_, emit) => _load(emit, showLoading: true));
    on<DashboardTicked>((_, emit) => _load(emit, showLoading: false));
    _ticker =
        Timer.periodic(_refreshInterval, (_) => add(const DashboardTicked()));
  }

  static const _refreshInterval = Duration(seconds: 60);
  static const _activityLimit = 10;

  final GetDashboardSummary _getSummary;
  final GetAuditEntries _getAuditEntries;
  late final Timer _ticker;

  bool _canReadUsers = false;
  bool _canReadAudit = false;

  Future<void> _onStart(DashboardStarted event, Emitter<DashboardState> emit) {
    _canReadUsers = event.canReadUsers;
    _canReadAudit = event.canReadAudit;
    return _load(emit, showLoading: true);
  }

  Future<void> _load(
    Emitter<DashboardState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const DashboardState(status: DashboardStatus.loading));
    }
    try {
      // Kick both reads off before awaiting so they run in parallel.
      final summaryFuture = _getSummary(includeUsers: _canReadUsers);
      final auditFuture =
          _canReadAudit ? _getAuditEntries(filter: const AuditFilter()) : null;

      final summary = await summaryFuture;
      final recent = auditFuture == null
          ? null
          : (await auditFuture)
              .entries
              .take(_activityLimit)
              .toList(growable: false);

      emit(DashboardState(
        status: DashboardStatus.loaded,
        summary: summary,
        recentActivity: recent,
      ));
    } catch (_) {
      // A silent tick failure keeps the last good view; only an explicit load
      // (open / pull-to-refresh) surfaces the error state.
      if (showLoading) {
        emit(const DashboardState(status: DashboardStatus.error));
      }
    }
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
