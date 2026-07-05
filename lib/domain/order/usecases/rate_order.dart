import '../repositories/order_repository.dart';

class RateOrder {
  const RateOrder(this._repository);

  final OrderRepository _repository;

  Future<void> call({
    required String orderId,
    required String shopId,
    required int rating,
  }) =>
      _repository.rateOrder(orderId: orderId, shopId: shopId, rating: rating);
}
