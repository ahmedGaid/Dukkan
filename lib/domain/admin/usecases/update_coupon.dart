import '../../promos/entities/coupon.dart';
import '../repositories/admin_promos_repository.dart';

class UpdateCoupon {
  const UpdateCoupon(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call(Coupon coupon) => _repository.updateCoupon(coupon);
}
