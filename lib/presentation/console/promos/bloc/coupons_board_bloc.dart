import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/create_coupon.dart';
import '../../../../domain/admin/usecases/delete_coupon.dart';
import '../../../../domain/admin/usecases/get_all_coupons.dart';
import '../../../../domain/admin/usecases/set_coupon_active.dart';
import '../../../../domain/admin/usecases/update_coupon.dart';
import '../../../../domain/promos/entities/coupon.dart';

part 'coupons_board_event.dart';
part 'coupons_board_state.dart';

/// Drives the الكوبونات tab of `/console/promos` (FC16). Every mutation is
/// Firestore-direct + best-effort audit; on success this reloads the whole
/// list so the board always shows the post-mutation truth — same contract as
/// `TaxonomyBoardBloc`.
class CouponsBoardBloc extends Bloc<CouponsBoardEvent, CouponsBoardState> {
  CouponsBoardBloc({
    required GetAllCoupons getAllCoupons,
    required CreateCoupon createCoupon,
    required UpdateCoupon updateCoupon,
    required SetCouponActive setCouponActive,
    required DeleteCoupon deleteCoupon,
  })  : _getAllCoupons = getAllCoupons,
        _createCoupon = createCoupon,
        _updateCoupon = updateCoupon,
        _setCouponActive = setCouponActive,
        _deleteCoupon = deleteCoupon,
        super(const CouponsBoardState()) {
    on<CouponsBoardStarted>(_onLoad);
    on<CouponsBoardRetryRequested>(_onLoad);
    on<CouponsBoardActiveToggled>(
      (e, emit) => _runAction(
        emit,
        () => _setCouponActive(code: e.code, value: e.value),
      ),
    );
    on<CouponsBoardCreateRequested>(
      (e, emit) => _runAction(emit, () => _createCoupon(e.coupon)),
    );
    on<CouponsBoardUpdateRequested>(
      (e, emit) => _runAction(emit, () => _updateCoupon(e.coupon)),
    );
    on<CouponsBoardDeleteRequested>(
      (e, emit) => _runAction(emit, () => _deleteCoupon(e.code)),
    );
  }

  final GetAllCoupons _getAllCoupons;
  final CreateCoupon _createCoupon;
  final UpdateCoupon _updateCoupon;
  final SetCouponActive _setCouponActive;
  final DeleteCoupon _deleteCoupon;

  Future<void> _onLoad(
    CouponsBoardEvent event,
    Emitter<CouponsBoardState> emit,
  ) async {
    emit(state.copyWith(status: CouponsBoardStatus.loading));
    try {
      final coupons = await _getAllCoupons();
      emit(state.copyWith(status: CouponsBoardStatus.loaded, coupons: coupons));
    } catch (_) {
      emit(state.copyWith(status: CouponsBoardStatus.error));
    }
  }

  Future<void> _runAction(
    Emitter<CouponsBoardState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: false));
    try {
      await action();
      final coupons = await _getAllCoupons();
      emit(state.copyWith(
        status: CouponsBoardStatus.loaded,
        actionBusy: false,
        coupons: coupons,
      ));
    } catch (_) {
      emit(state.copyWith(actionBusy: false, actionError: true));
    }
  }
}
