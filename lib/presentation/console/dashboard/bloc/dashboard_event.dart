part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open. Carries the viewer's read permissions (resolved
/// from the AuthBloc in the page) so the bloc — including its silent auto
/// refresh — knows which permission-gated queries it may run.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted({
    required this.canReadUsers,
    required this.canReadAudit,
  });

  final bool canReadUsers;
  final bool canReadAudit;

  @override
  List<Object?> get props => [canReadUsers, canReadAudit];
}

/// Pull-to-refresh — re-runs the same load, showing the loading skeleton.
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

/// The 60-second auto-refresh tick — reloads silently (no skeleton flash) and
/// keeps the last good view if the refresh fails.
class DashboardTicked extends DashboardEvent {
  const DashboardTicked();
}
