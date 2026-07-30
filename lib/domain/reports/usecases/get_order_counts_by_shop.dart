import '../repositories/reports_repository.dart';

/// Thin pass-through.
class GetOrderCountsByShop {
  const GetOrderCountsByShop(this._repository);

  final ReportsRepository _repository;

  Future<Map<String, int>> call(List<String> shopIds) =>
      _repository.getOrderCountsByShop(shopIds);
}
