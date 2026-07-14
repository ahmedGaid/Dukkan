import '../../order/entities/order.dart';
import '../repositories/admin_orders_repository.dart';

/// The board's "order id" search field — a direct doc get. Named distinctly
/// from `GetUserById` (auth) since both can be in scope together.
class GetConsoleOrderById {
  const GetConsoleOrderById(this._repository);

  final AdminOrdersRepository _repository;

  Future<Order?> call(String orderId) => _repository.getOrderById(orderId);
}
