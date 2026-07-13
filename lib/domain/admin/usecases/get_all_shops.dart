import '../../shop/entities/shop.dart';
import '../repositories/admin_shops_repository.dart';

/// Loads every shop for the console board, unfiltered. Thin pass-through —
/// matches `GetUsers`.
class GetAllShops {
  const GetAllShops(this._repository);

  final AdminShopsRepository _repository;

  Future<List<Shop>> call() => _repository.getAllShops();
}
