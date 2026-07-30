import '../../../domain/reports/entities/report_period_totals.dart';
import '../../../domain/reports/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._remote);

  final ReportsRemoteDataSource _remote;

  @override
  Future<ReportPeriodTotals> getPeriodTotals({required int periodDays}) =>
      _remote.getPeriodTotals(periodDays: periodDays);

  @override
  Future<Map<String, int>> getOrderCountsByShop(List<String> shopIds) =>
      _remote.getOrderCountsByShop(shopIds);
}
