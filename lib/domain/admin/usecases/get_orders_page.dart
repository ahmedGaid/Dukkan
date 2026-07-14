import '../entities/orders_page.dart';
import '../repositories/admin_orders_repository.dart';

/// Loads one page of the console order board. Thin pass-through — matches `GetUsers`.
class GetOrdersPage {
  const GetOrdersPage(this._repository);

  final AdminOrdersRepository _repository;

  Future<OrdersPage> call({String? status, DateTime? cursor}) =>
      _repository.getOrders(status: status, cursor: cursor);
}
