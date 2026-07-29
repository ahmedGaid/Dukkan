import 'entities/coupon.dart';

enum CouponRejectReason { inactive, expired, belowMinOrder, maxedOut }

/// Pure coupon math — no Firestore/BuildContext dependency, so it's
/// unit-testable directly (see `test/domain/promos/coupon_discount_test.dart`).
class CouponDiscount {
  const CouponDiscount._();

  /// Percent: round-half-up on basis points, same idiom as
  /// `PlatformConfig.commissionForSubtotal` (an odd subtotal like 333 piasters
  /// × 500 bps rounds to 17, not 16). Fixed: clamped to the subtotal so a
  /// discount can never exceed the order's own goods value.
  static int computeDiscountMinor(Coupon coupon, int subtotalMinor) {
    if (coupon.type == CouponType.percent) {
      final bps = coupon.valueBps ?? 0;
      return (subtotalMinor * bps + 5000) ~/ 10000;
    }
    final fixed = coupon.valueMinor ?? 0;
    return fixed > subtotalMinor ? subtotalMinor : fixed;
  }

  /// Null = valid. Checked in this order so the checkout error copy is
  /// deterministic when more than one condition fails at once.
  static CouponRejectReason? validate(
    Coupon coupon, {
    required int subtotalMinor,
    required DateTime now,
  }) {
    if (!coupon.isActive) return CouponRejectReason.inactive;
    if (coupon.expiresAt != null && now.isAfter(coupon.expiresAt!)) {
      return CouponRejectReason.expired;
    }
    if (subtotalMinor < coupon.minOrderMinor) {
      return CouponRejectReason.belowMinOrder;
    }
    final maxUses = coupon.maxUses;
    if (maxUses != null && coupon.usedCount >= maxUses) {
      return CouponRejectReason.maxedOut;
    }
    return null;
  }
}
