import '../entities/coupon.dart';

/// Customer-facing coupon access (checkout). Reads are Firestore-direct and
/// client-validated (see `coupon_discount.dart`) — bounded but not
/// Worker-verified (honesty note: FILE_16_PROMOTIONS.md Task A).
abstract class CouponRepository {
  /// Doc lookup by uppercase code — null if it doesn't exist.
  Future<Coupon?> getByCode(String code);

  /// Bumps `usedCount` by exactly +1 (rules-enforced shape, mirrors the shop
  /// rating bump). Called once, right after a successful order placement.
  Future<void> redeem(String code);
}
