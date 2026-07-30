import '../entities/report_period_totals.dart';
import '../repositories/reports_repository.dart';

/// Thin pass-through.
class GetReportPeriodTotals {
  const GetReportPeriodTotals(this._repository);

  final ReportsRepository _repository;

  Future<ReportPeriodTotals> call({required int periodDays}) =>
      _repository.getPeriodTotals(periodDays: periodDays);
}
