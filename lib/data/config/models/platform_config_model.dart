import '../../../domain/config/entities/platform_config.dart';

class PlatformConfigModel extends PlatformConfig {
  const PlatformConfigModel({
    required super.commissionBps,
    required super.deliveryFeeMinor,
    required super.driverDeliveryShareMinor,
    super.minOrderMinor,
    super.vatBps,
    super.supportPhone,
    super.supportWhatsApp,
    super.businessHoursNote,
    super.maintenanceMode,
    super.minSupportedBuild,
  });

  /// All new (M12) fields are optional-with-default so a live doc that only
  /// has the original 3 M12 fields still parses cleanly.
  factory PlatformConfigModel.fromFirestore(Map<String, dynamic> data) {
    return PlatformConfigModel(
      commissionBps: (data['commissionBps'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (data['deliveryFeeMinor'] as num?)?.toInt() ?? 0,
      driverDeliveryShareMinor:
          (data['driverDeliveryShareMinor'] as num?)?.toInt() ?? 0,
      minOrderMinor: (data['minOrderMinor'] as num?)?.toInt() ?? 0,
      vatBps: (data['vatBps'] as num?)?.toInt() ?? 0,
      supportPhone: data['supportPhone'] as String? ?? '',
      supportWhatsApp: data['supportWhatsApp'] as String? ?? '',
      businessHoursNote: data['businessHoursNote'] as String? ?? '',
      maintenanceMode: data['maintenanceMode'] as bool? ?? false,
      minSupportedBuild: (data['minSupportedBuild'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'commissionBps': commissionBps,
        'deliveryFeeMinor': deliveryFeeMinor,
        'driverDeliveryShareMinor': driverDeliveryShareMinor,
        'minOrderMinor': minOrderMinor,
        'vatBps': vatBps,
        'supportPhone': supportPhone,
        'supportWhatsApp': supportWhatsApp,
        'businessHoursNote': businessHoursNote,
        'maintenanceMode': maintenanceMode,
        'minSupportedBuild': minSupportedBuild,
      };
}
