import 'package:equatable/equatable.dart';

/// A delivery coverage district. Seed-managed at first (M8); console-editable
/// from FC9 (`/areas`, gated by `geo.edit`). Referenced by id from a
/// customer's [Address] and from a [Driver]'s `areaIds`.
class Area extends Equatable {
  const Area({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sort,
    this.governorate = 'الإسماعيلية',
    this.city = 'الإسماعيلية',
    this.isActive = true,
    this.deliveryFeeMinorOverride,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int sort;

  /// FC9: groups the console's geo list; Egypt-only, no country/postal field.
  final String governorate;
  final String city;

  /// FC9: hides the area from checkout's picker without deleting it —
  /// existing orders keep their `deliveryAddress.areaId` unchanged.
  final bool isActive;

  /// FC9, piasters. Null = use `PlatformConfig.deliveryFeeMinor`; see the
  /// resolution-order note in `PlaceOrder`.
  final int? deliveryFeeMinorOverride;

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        sort,
        governorate,
        city,
        isActive,
        deliveryFeeMinorOverride,
      ];
}
