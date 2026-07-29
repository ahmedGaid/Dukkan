part of 'coupons_board_bloc.dart';

enum CouponsBoardStatus { loading, loaded, error }

class CouponsBoardState extends Equatable {
  const CouponsBoardState({
    this.status = CouponsBoardStatus.loading,
    this.coupons = const [],
    this.actionBusy = false,
    this.actionError = false,
  });

  final CouponsBoardStatus status;
  final List<Coupon> coupons;
  final bool actionBusy;

  /// One-shot flag for the page's snackbar listener — reset to false on
  /// every successful reload, so it never re-fires on rebuild.
  final bool actionError;

  CouponsBoardState copyWith({
    CouponsBoardStatus? status,
    List<Coupon>? coupons,
    bool? actionBusy,
    bool? actionError,
  }) {
    return CouponsBoardState(
      status: status ?? this.status,
      coupons: coupons ?? this.coupons,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [status, coupons, actionBusy, actionError];
}
