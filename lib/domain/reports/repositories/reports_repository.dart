import '../entities/report_period_totals.dart';

/// Founder Console reports (FC17). Every figure is an aggregate query
/// (`count()`/`sum()`) — no document downloads, the M13/FC5 dashboard lesson.
/// No cache — always a fresh read for the selected period, mirrors
/// `DashboardRepository`.
abstract class ReportsRepository {
  /// The [periodDays]-day (7/30/90) daily series + totals + growth counts.
  Future<ReportPeriodTotals> getPeriodTotals({required int periodDays});

  /// `orders` count per shop id, for the «orders by shop top-10» row — one
  /// aggregate query per id (small-marketplace scale, same tradeoff as the
  /// dashboard's per-day loop).
  Future<Map<String, int>> getOrderCountsByShop(List<String> shopIds);
}
