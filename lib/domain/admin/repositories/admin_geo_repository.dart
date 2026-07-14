import '../../areas/entities/area.dart';

/// Founder Console geo management (FC9). Reads are Firestore-direct and
/// unfiltered (including deactivated areas) — the checkout-facing filter
/// lives only in `AreasRepositoryImpl`. Every write is Firestore-direct,
/// gated by the `geo.edit` rules branch.
abstract class AdminGeoRepository {
  /// Every area, sorted by `sort`, including deactivated ones.
  Future<List<Area>> getAllAreas();

  /// Auto-id'd, `sort` lands after the current highest.
  Future<void> createArea({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  });

  Future<void> updateArea({
    required String areaId,
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  });

  Future<void> setAreaActive({required String areaId, required bool value});

  /// Real delete — only safe when [countOrdersInArea] is zero; the console
  /// falls back to [setAreaActive]`(value: false)` otherwise.
  Future<void> deleteArea(String areaId);

  /// `orders` where `deliveryAddress.areaId == areaId` — the console's
  /// pre-delete count. An aggregate `.count()`, no document downloads.
  Future<int> countOrdersInArea(String areaId);
}
