import '../repositories/admin_shops_repository.dart';

/// Undoes [SoftDeleteShop]. Thin pass-through.
class RestoreShop {
  const RestoreShop(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call(String shopId) => _repository.restore(shopId);
}
