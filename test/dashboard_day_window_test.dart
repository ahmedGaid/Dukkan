import 'package:dukkan/data/dashboard/datasources/day_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startOfDay strips the time to local midnight', () {
    final now = DateTime(2026, 7, 13, 15, 42, 30);
    expect(startOfDay(now), DateTime(2026, 7, 13));
  });

  test('last7DayStarts returns 7 local midnights, oldest-first, ending today',
      () {
    final now = DateTime(2026, 7, 13, 9);
    final days = last7DayStarts(now);

    expect(days, [
      DateTime(2026, 7, 7),
      DateTime(2026, 7, 8),
      DateTime(2026, 7, 9),
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 11),
      DateTime(2026, 7, 12),
      DateTime(2026, 7, 13),
    ]);
  });

  test('last7DayStarts rolls back across a month boundary', () {
    final now = DateTime(2026, 3, 2, 12);
    final days = last7DayStarts(now);
    expect(days.first, DateTime(2026, 2, 24));
    expect(days.last, DateTime(2026, 3, 2));
  });

  test('nextDay is the following local midnight (bucket upper bound)', () {
    expect(nextDay(DateTime(2026, 7, 13)), DateTime(2026, 7, 14));
    expect(nextDay(DateTime(2026, 2, 28)), DateTime(2026, 3, 1)); // non-leap
  });
}
