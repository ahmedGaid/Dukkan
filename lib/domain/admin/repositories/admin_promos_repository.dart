import '../../promos/entities/coupon.dart';
import '../../promos/entities/promo_banner.dart';

/// Founder Console promotions management (FC16) — one repository for both
/// tabs of `/console/promos` (coupons + banners), mirroring the one-route/
/// one-repository shape of `AdminUsersRepository`/`AdminShopsRepository`.
/// Reads are Firestore-direct and unfiltered (including inactive/expired);
/// every mutation is Firestore-direct, gated by the `promos.edit` rules
/// branch, with a best-effort audit report (no Worker route needed — neither
/// collection has a field a client must never touch, unlike shop ownership).
abstract class AdminPromosRepository {
  // --- Coupons ---

  /// Every coupon, unfiltered, sorted by code.
  Future<List<Coupon>> getAllCoupons();

  /// [code] is forced uppercase by the console form; the doc id IS the code.
  Future<void> createCoupon(Coupon coupon);

  /// Coupon codes are immutable once created (the doc id) — this replaces
  /// every other field.
  Future<void> updateCoupon(Coupon coupon);

  Future<void> setCouponActive({required String code, required bool value});

  Future<void> deleteCoupon(String code);

  // --- Banners ---

  /// Every banner, unfiltered (inactive/expired included), sorted by `sort`.
  Future<List<PromoBanner>> getAllBanners();

  /// `sort` lands after the current highest.
  Future<void> createBanner({
    required String imageUrl,
    required BannerTargetType targetType,
    String? targetId,
    String? targetShopId,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  Future<void> updateBanner(PromoBanner banner);

  Future<void> setBannerActive({required String id, required bool value});

  /// Swaps the `sort` value of two adjacent banners (an up/down reorder tap)
  /// in one batch — mirrors `AdminTaxonomyRepository.swapSort`.
  Future<void> swapBannerSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  });

  Future<void> deleteBanner(String id);
}
