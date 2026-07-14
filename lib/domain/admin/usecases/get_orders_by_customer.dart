import '../../order/entities/order.dart';
import '../repositories/admin_orders_repository.dart';

/// The board's "exact phone" search, second half — once `GetUserByPhone`
/// resolves the phone to a uid, this fetches that customer's orders.
class GetOrdersByCustomer {
  const GetOrdersByCustomer(this._repository);

  final AdminOrdersRepository _repository;

  Future<List<Order>> call(String customerUid) =>
      _repository.getOrdersByCustomerUid(customerUid);
}
