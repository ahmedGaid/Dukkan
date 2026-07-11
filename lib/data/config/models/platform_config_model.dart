import '../../../domain/config/entities/platform_config.dart';

class PlatformConfigModel extends PlatformConfig {
  const PlatformConfigModel({
    required super.commissionBps,
    required super.deliveryFeeMinor,
    required super.driverDeliveryShareMinor,
  });

  factory PlatformConfigModel.fromFirestore(Map<String, dynamic> data) {
    return PlatformConfigModel(
      commissionBps: (data['commissionBps'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (data['deliveryFeeMinor'] as num?)?.toInt() ?? 0,
      driverDeliveryShareMinor:
          (data['driverDeliveryShareMinor'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'commissionBps': commissionBps,
        'deliveryFeeMinor': deliveryFeeMinor,
        'driverDeliveryShareMinor': driverDeliveryShareMinor,
      };
}
