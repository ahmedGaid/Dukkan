import '../repositories/admin_promos_repository.dart';

class DeleteCoupon {
  const DeleteCoupon(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call(String code) => _repository.deleteCoupon(code);
}
