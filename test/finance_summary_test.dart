import 'package:dukkan/core/money.dart';
import 'package:dukkan/domain/finance/entities/finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceSummary.platformRevenueMinor (M13, revenue addition)', () {
    test('is commission plus delivery revenue', () {
      const summary = FinanceSummary(
        totalOrders: 5,
        deliveredOrders: 3,
        cancelledOrders: 1,
        commissionMinor: 2500,
        deliveryRevenueMinor: 500,
      );
      expect(summary.platformRevenueMinor, 3000);
    });

    test('zero commission and zero delivery revenue sum to zero', () {
      const summary = FinanceSummary(
        totalOrders: 0,
        deliveredOrders: 0,
        cancelledOrders: 0,
        commissionMinor: 0,
        deliveryRevenueMinor: 0,
      );
      expect(summary.platformRevenueMinor, 0);
    });
  });

  group('Money.format minor-units boundary (finance tiles show large totals)', () {
    test('a whole-pound total drops the decimals', () {
      expect(Money.format(300000, languageCode: 'en'), 'EGP 3,000');
    });

    test('a total with odd piasters keeps two decimals', () {
      expect(Money.format(300050, languageCode: 'en'), 'EGP 3,000.50');
    });

    test('one piaster short of a whole pound still shows decimals', () {
      expect(Money.format(299999, languageCode: 'en'), 'EGP 2,999.99');
    });
  });
}
