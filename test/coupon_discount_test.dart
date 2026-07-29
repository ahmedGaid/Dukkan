import 'package:dukkan/domain/promos/coupon_discount.dart';
import 'package:dukkan/domain/promos/entities/coupon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDiscountMinor', () {
    test('percent rounds half-up on an odd subtotal', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.percent,
        valueBps: 500, // 5%
        minOrderMinor: 0,
      );
      // (333 * 500 + 5000) / 10000 = 17.15 -> 17 (integer division), matches
      // PlatformConfig.commissionForSubtotal's exact idiom.
      expect(CouponDiscount.computeDiscountMinor(coupon, 333), 17);
    });

    test('fixed discount larger than the subtotal clamps to the subtotal', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100000,
        minOrderMinor: 0,
      );
      expect(CouponDiscount.computeDiscountMinor(coupon, 2000), 2000);
    });

    test('fixed discount smaller than the subtotal is unclamped', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 500,
        minOrderMinor: 0,
      );
      expect(CouponDiscount.computeDiscountMinor(coupon, 2000), 500);
    });
  });

  group('validate', () {
    final now = DateTime(2026, 1, 1);

    test('inactive coupon is rejected', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        isActive: false,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        CouponRejectReason.inactive,
      );
    });

    test('expired coupon is rejected', () {
      final coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        CouponRejectReason.expired,
      );
    });

    test('a not-yet-expired coupon passes the expiry check', () {
      final coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        expiresAt: now.add(const Duration(days: 1)),
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        isNull,
      );
    });

    test('subtotal below minOrderMinor is rejected', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 5000,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 4999, now: now),
        CouponRejectReason.belowMinOrder,
      );
    });

    test('usedCount at maxUses is rejected', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        maxUses: 3,
        usedCount: 3,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        CouponRejectReason.maxedOut,
      );
    });

    test('usedCount below maxUses is valid', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        maxUses: 3,
        usedCount: 2,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        isNull,
      );
    });

    test('null maxUses means unlimited', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.fixed,
        valueMinor: 100,
        minOrderMinor: 0,
        usedCount: 1000000,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        isNull,
      );
    });

    test('a fully valid coupon returns null', () {
      const coupon = Coupon(
        code: 'X',
        type: CouponType.percent,
        valueBps: 1000,
        minOrderMinor: 500,
      );
      expect(
        CouponDiscount.validate(coupon, subtotalMinor: 1000, now: now),
        isNull,
      );
    });
  });
}
