import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/promos/entities/promo_banner.dart';

class PromoBannerModel extends PromoBanner {
  const PromoBannerModel({
    required super.id,
    required super.imageUrl,
    required super.targetType,
    required super.sort,
    super.targetId,
    super.targetShopId,
    super.isActive,
    super.startsAt,
    super.endsAt,
  });

  factory PromoBannerModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PromoBannerModel(
      id: id,
      imageUrl: data['imageUrl'] as String? ?? '',
      targetType: _targetTypeFromWire(data['targetType'] as String?),
      targetId: data['targetId'] as String?,
      targetShopId: data['targetShopId'] as String?,
      sort: (data['sort'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
    );
  }

  static BannerTargetType _targetTypeFromWire(String? wire) => switch (wire) {
        'shop' => BannerTargetType.shop,
        'product' => BannerTargetType.product,
        _ => BannerTargetType.none,
      };

  Map<String, dynamic> toFirestore() => {
        'imageUrl': imageUrl,
        'targetType': targetType.name,
        if (targetId != null) 'targetId': targetId,
        if (targetShopId != null) 'targetShopId': targetShopId,
        'sort': sort,
        'isActive': isActive,
        if (startsAt != null) 'startsAt': Timestamp.fromDate(startsAt!),
        if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
      };
}
