import '../repositories/admin_promos_repository.dart';

class SetCouponActive {
  const SetCouponActive(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call({required String code, required bool value}) =>
      _repository.setCouponActive(code: code, value: value);
}
