import '../entities/coupon.dart';
import '../repositories/coupon_repository.dart';

/// Thin pass-through — matches `GetAreas`. Caller (checkout) uppercases the
/// code before calling.
class GetCouponByCode {
  const GetCouponByCode(this._repository);

  final CouponRepository _repository;

  Future<Coupon?> call(String code) => _repository.getByCode(code);
}
