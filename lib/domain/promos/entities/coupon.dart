import 'package:equatable/equatable.dart';

enum CouponType { percent, fixed }

/// A discount code (FC16 Task A). Doc id is the uppercase [code] itself —
/// checkout looks it up by id, no query needed. `valueBps` (percent) or
/// `valueMinor` (fixed) is set depending on [type], never both.
class Coupon extends Equatable {
  const Coupon({
    required this.code,
    required this.type,
    required this.minOrderMinor,
    this.valueBps,
    this.valueMinor,
    this.expiresAt,
    this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
  });

  final String code;
  final CouponType type;
  final int? valueBps;
  final int? valueMinor;
  final int minOrderMinor;
  final DateTime? expiresAt;

  /// Null = unlimited uses.
  final int? maxUses;
  final int usedCount;
  final bool isActive;

  @override
  List<Object?> get props => [
        code,
        type,
        valueBps,
        valueMinor,
        minOrderMinor,
        expiresAt,
        maxUses,
        usedCount,
        isActive,
      ];
}
