import 'package:dukkan/data/config/models/platform_config_model.dart';
import 'package:dukkan/domain/config/entities/platform_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformConfigModel.fromFirestore (M12 Task A, additive fields)', () {
    test('a live doc with only the 3 original M12 fields parses with defaults', () {
      final config = PlatformConfigModel.fromFirestore({
        'commissionBps': 500,
        'deliveryFeeMinor': 3000,
        'driverDeliveryShareMinor': 2500,
      });

      expect(config.commissionBps, 500);
      expect(config.deliveryFeeMinor, 3000);
      expect(config.driverDeliveryShareMinor, 2500);
      expect(config.minOrderMinor, 0);
      expect(config.vatBps, 0);
      expect(config.supportPhone, '');
      expect(config.supportWhatsApp, '');
      expect(config.businessHoursNote, '');
      expect(config.maintenanceMode, false);
      expect(config.minSupportedBuild, 0);
    });
  });

  group('PlatformConfig.commissionForSubtotal (M12, round-half-up)', () {
    const config = PlatformConfig(
      commissionBps: 500, // 5%
      deliveryFeeMinor: 3000,
      driverDeliveryShareMinor: 2500,
    );

    test('500 EGP subtotal at 5% is exactly 25 EGP', () {
      expect(config.commissionForSubtotal(50000), 2500);
    });

    test('odd subtotal rounds the half-piaster up', () {
      // 333 piasters * 500 bps / 10000 = 16.65 -> rounds up to 17.
      expect(config.commissionForSubtotal(333), 17);
    });

    test('zero subtotal is zero commission', () {
      expect(config.commissionForSubtotal(0), 0);
    });

    test('platformDeliveryShareMinor is fee minus driver share', () {
      expect(config.platformDeliveryShareMinor, 500);
    });
  });
}
