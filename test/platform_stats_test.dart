import 'package:dukkan/core/firestore/platform_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dailyStatsDocId zero-pads single-digit month and day', () {
    expect(dailyStatsDocId(DateTime(2026, 1, 3)), 'daily-2026-01-03');
  });

  test('dailyStatsDocId ignores the time-of-day component', () {
    expect(
      dailyStatsDocId(DateTime(2026, 8, 11, 23, 59, 59)),
      'daily-2026-08-11',
    );
  });

  test('dailyStatsDocId handles double-digit month and day unpadded', () {
    expect(dailyStatsDocId(DateTime(2026, 12, 25)), 'daily-2026-12-25');
  });
}
