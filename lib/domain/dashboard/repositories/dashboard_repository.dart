import '../entities/dashboard_summary.dart';

/// Founder Console dashboard boundary (FC5). A fresh remote read every time —
/// the console pulls-to-refresh (and auto-refreshes) for live numbers, so there
/// is no cache branch, same contract as `FinanceRepository`.
abstract class DashboardRepository {
  /// A fresh aggregate snapshot. [includeUsers] runs the `/users` count only
  /// when the caller holds `users.read`; otherwise
  /// [DashboardSummary.totalUsers] comes back null.
  Future<DashboardSummary> getSummary({required bool includeUsers});
}
