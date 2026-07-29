import 'package:equatable/equatable.dart';

/// Named `PromoBanner`, not `Banner` — Flutter's material library already owns
/// that name.
enum BannerTargetType { shop, product, none }

/// A marketing banner shown at the head of the home carousel (FC16 Task B).
/// `startsAt`/`endsAt` are both optional — a null bound means "no limit on
/// that side".
class PromoBanner extends Equatable {
  const PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.targetType,
    required this.sort,
    this.targetId,
    this.targetShopId,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String imageUrl;
  final BannerTargetType targetType;

  /// Shop or product id, depending on [targetType]. Null when [targetType]
  /// is [BannerTargetType.none].
  final String? targetId;

  /// Denormalized at creation time when [targetType] is
  /// [BannerTargetType.product] — the product's own `shopId`, so a tap can
  /// navigate straight to `/shop/:shopId/product/:id` with no extra lookup.
  /// Null otherwise.
  final String? targetShopId;
  final int sort;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// [isActive] and, when set, `now` falls inside the [startsAt]/[endsAt]
  /// window. Pure so it's testable without a clock dependency at the call
  /// site.
  bool isLiveAt(DateTime now) {
    if (!isActive) return false;
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        imageUrl,
        targetType,
        targetId,
        targetShopId,
        sort,
        isActive,
        startsAt,
        endsAt,
      ];
}
