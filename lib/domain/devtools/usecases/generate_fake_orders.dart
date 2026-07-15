import '../repositories/devtools_repository.dart';

class GenerateFakeOrders {
  const GenerateFakeOrders(this._repository);

  final DevToolsRepository _repository;

  Future<int> call({
    required String shopId,
    required List<Map<String, dynamic>> products,
    required List<String> customerUids,
    required int count,
  }) =>
      _repository.generateFakeOrders(
        shopId: shopId,
        products: products,
        customerUids: customerUids,
        count: count,
      );
}
