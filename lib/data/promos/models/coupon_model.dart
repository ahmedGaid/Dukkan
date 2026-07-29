import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/promos/entities/coupon.dart';

class CouponModel extends Coupon {
  const CouponModel({
    required super.code,
    required super.type,
    required super.minOrderMinor,
    super.valueBps,
    super.valueMinor,
    super.expiresAt,
    super.maxUses,
    super.usedCount,
    super.isActive,
  });

  factory CouponModel.fromFirestore(String code, Map<String, dynamic> data) {
    return CouponModel(
      code: code,
      type: (data['type'] as String?) == 'fixed'
          ? CouponType.fixed
          : CouponType.percent,
      valueBps: (data['valueBps'] as num?)?.toInt(),
      valueMinor: (data['valueMinor'] as num?)?.toInt(),
      minOrderMinor: (data['minOrderMinor'] as num?)?.toInt() ?? 0,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      maxUses: (data['maxUses'] as num?)?.toInt(),
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type == CouponType.fixed ? 'fixed' : 'percent',
        if (valueBps != null) 'valueBps': valueBps,
        if (valueMinor != null) 'valueMinor': valueMinor,
        'minOrderMinor': minOrderMinor,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        if (maxUses != null) 'maxUses': maxUses,
        'usedCount': usedCount,
        'isActive': isActive,
      };
}
