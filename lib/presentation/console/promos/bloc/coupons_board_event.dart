part of 'coupons_board_bloc.dart';

sealed class CouponsBoardEvent extends Equatable {
  const CouponsBoardEvent();

  @override
  List<Object?> get props => [];
}

class CouponsBoardStarted extends CouponsBoardEvent {
  const CouponsBoardStarted();
}

class CouponsBoardRetryRequested extends CouponsBoardEvent {
  const CouponsBoardRetryRequested();
}

class CouponsBoardActiveToggled extends CouponsBoardEvent {
  const CouponsBoardActiveToggled(this.code, this.value);

  final String code;
  final bool value;

  @override
  List<Object?> get props => [code, value];
}

class CouponsBoardCreateRequested extends CouponsBoardEvent {
  const CouponsBoardCreateRequested(this.coupon);

  final Coupon coupon;

  @override
  List<Object?> get props => [coupon];
}

class CouponsBoardUpdateRequested extends CouponsBoardEvent {
  const CouponsBoardUpdateRequested(this.coupon);

  final Coupon coupon;

  @override
  List<Object?> get props => [coupon];
}

class CouponsBoardDeleteRequested extends CouponsBoardEvent {
  const CouponsBoardDeleteRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
