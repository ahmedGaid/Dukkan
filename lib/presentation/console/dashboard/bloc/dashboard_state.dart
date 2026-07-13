part of 'dashboard_bloc.dart';

enum DashboardStatus { loading, loaded, error }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.summary,
    this.recentActivity,
  });

  final DashboardStatus status;
  final DashboardSummary? summary;

  /// The last few audit entries for the activity strip, or null when the viewer
  /// lacks `auditlogs.read` — the activity card and the audit quick action are
  /// then hidden entirely. An empty list means "permitted, none yet".
  final List<AuditEntry>? recentActivity;

  bool get canViewAudit => recentActivity != null;

  @override
  List<Object?> get props => [status, summary, recentActivity];
}
