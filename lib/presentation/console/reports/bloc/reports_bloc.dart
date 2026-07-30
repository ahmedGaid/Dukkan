import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/count_orders_in_area.dart';
import '../../../../domain/admin/usecases/count_products_in_category.dart';
import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/get_all_categories.dart';
import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/reports/entities/distribution_entry.dart';
import '../../../../domain/reports/entities/report_period_totals.dart';
import '../../../../domain/reports/usecases/get_order_counts_by_shop.dart';
import '../../../../domain/reports/usecases/get_report_period_totals.dart';

part 'reports_event.dart';
part 'reports_state.dart';

/// Drives `/console/reports` (FC17). One load per period change: the period
/// totals (daily series + growth) and the three «التوزيع» distribution lists
/// all run together — reusing `CountOrdersInArea`/`CountProductsInCategory`
/// (already shipped for FC9's pre-delete warnings) rather than new queries.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required GetReportPeriodTotals getReportPeriodTotals,
    required GetAllAreas getAllAreas,
    required CountOrdersInArea countOrdersInArea,
    required GetAllCategories getAllCategories,
    required CountProductsInCategory countProductsInCategory,
    required GetAllShops getAllShops,
    required GetOrderCountsByShop getOrderCountsByShop,
  })  : _getReportPeriodTotals = getReportPeriodTotals,
        _getAllAreas = getAllAreas,
        _countOrdersInArea = countOrdersInArea,
        _getAllCategories = getAllCategories,
        _countProductsInCategory = countProductsInCategory,
        _getAllShops = getAllShops,
        _getOrderCountsByShop = getOrderCountsByShop,
        super(const ReportsState()) {
    on<ReportsStarted>((e, emit) => _load(emit, state.periodDays));
    on<ReportsRetryRequested>((e, emit) => _load(emit, state.periodDays));
    on<ReportsPeriodChanged>((e, emit) => _load(emit, e.periodDays));
  }

  final GetReportPeriodTotals _getReportPeriodTotals;
  final GetAllAreas _getAllAreas;
  final CountOrdersInArea _countOrdersInArea;
  final GetAllCategories _getAllCategories;
  final CountProductsInCategory _countProductsInCategory;
  final GetAllShops _getAllShops;
  final GetOrderCountsByShop _getOrderCountsByShop;

  Future<void> _load(Emitter<ReportsState> emit, int periodDays) async {
    emit(state.copyWith(status: ReportsStatus.loading, periodDays: periodDays));
    try {
      final totalsFuture = _getReportPeriodTotals(periodDays: periodDays);
      final areasFuture = _loadAreaDistribution();
      final categoriesFuture = _loadCategoryDistribution();
      final shopsFuture = _loadShopDistribution();

      final totals = await totalsFuture;
      final areas = await areasFuture;
      final categories = await categoriesFuture;
      final shops = await shopsFuture;

      emit(state.copyWith(
        status: ReportsStatus.loaded,
        totals: totals,
        ordersByArea: areas,
        productsByCategory: categories,
        ordersByShop: shops,
      ));
    } catch (_) {
      emit(state.copyWith(status: ReportsStatus.error));
    }
  }

  Future<List<DistributionEntry>> _loadAreaDistribution() async {
    final areas = (await _getAllAreas()).where((a) => a.isActive).toList(growable: false);
    final counts = await Future.wait(areas.map((a) => _countOrdersInArea(a.id)));
    final entries = [
      for (var i = 0; i < areas.length; i++)
        DistributionEntry(labelAr: areas[i].nameAr, labelEn: areas[i].nameEn, count: counts[i]),
    ];
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }

  Future<List<DistributionEntry>> _loadCategoryDistribution() async {
    final categories =
        (await _getAllCategories()).where((c) => c.isVisible).toList(growable: false);
    final counts = await Future.wait(categories.map((c) => _countProductsInCategory(c.id)));
    final entries = [
      for (var i = 0; i < categories.length; i++)
        DistributionEntry(
          labelAr: categories[i].nameAr,
          labelEn: categories[i].nameEn,
          count: counts[i],
        ),
    ];
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }

  Future<List<DistributionEntry>> _loadShopDistribution() async {
    final shops = await _getAllShops();
    final counts = await _getOrderCountsByShop(shops.map((s) => s.id).toList(growable: false));
    final entries = [
      for (final shop in shops)
        DistributionEntry(labelAr: shop.nameAr, labelEn: shop.name, count: counts[shop.id] ?? 0),
    ];
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(10).toList(growable: false);
  }
}
