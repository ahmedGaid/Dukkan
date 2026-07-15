import '../../order/entities/order.dart';
import '../repositories/admin_drivers_repository.dart';

/// Orders this driver currently carries — the console detail page's
/// assigned-orders list. Thin pass-through.
class GetDriverAssignedOrders {
  const GetDriverAssignedOrders(this._repository);

  final AdminDriversRepository _repository;

  Future<List<Order>> call(String uid) => _repository.getAssignedOrders(uid);
}
