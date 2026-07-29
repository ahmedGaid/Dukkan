import '../repositories/coupon_repository.dart';

class RedeemCoupon {
  const RedeemCoupon(this._repository);

  final CouponRepository _repository;

  Future<void> call(String code) => _repository.redeem(code);
}
