import 'package:dukkan/domain/promos/entities/promo_banner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 15);

  test('inactive banner is never live', () {
    const banner = PromoBanner(
      id: 'b',
      imageUrl: 'x',
      targetType: BannerTargetType.none,
      sort: 0,
      isActive: false,
    );
    expect(banner.isLiveAt(now), isFalse);
  });

  test('active banner with no date window is live', () {
    const banner = PromoBanner(
      id: 'b',
      imageUrl: 'x',
      targetType: BannerTargetType.none,
      sort: 0,
    );
    expect(banner.isLiveAt(now), isTrue);
  });

  test('before startsAt is not live', () {
    final banner = PromoBanner(
      id: 'b',
      imageUrl: 'x',
      targetType: BannerTargetType.none,
      sort: 0,
      startsAt: now.add(const Duration(days: 1)),
    );
    expect(banner.isLiveAt(now), isFalse);
  });

  test('after endsAt is not live', () {
    final banner = PromoBanner(
      id: 'b',
      imageUrl: 'x',
      targetType: BannerTargetType.none,
      sort: 0,
      endsAt: now.subtract(const Duration(days: 1)),
    );
    expect(banner.isLiveAt(now), isFalse);
  });

  test('inside the date window is live', () {
    final banner = PromoBanner(
      id: 'b',
      imageUrl: 'x',
      targetType: BannerTargetType.none,
      sort: 0,
      startsAt: now.subtract(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 1)),
    );
    expect(banner.isLiveAt(now), isTrue);
  });
}
