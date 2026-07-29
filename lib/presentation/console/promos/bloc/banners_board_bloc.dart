import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/create_banner.dart';
import '../../../../domain/admin/usecases/delete_banner.dart';
import '../../../../domain/admin/usecases/get_all_banners.dart';
import '../../../../domain/admin/usecases/set_banner_active.dart';
import '../../../../domain/admin/usecases/swap_banner_sort.dart';
import '../../../../domain/admin/usecases/update_banner.dart';
import '../../../../domain/promos/entities/promo_banner.dart';

part 'banners_board_event.dart';
part 'banners_board_state.dart';

/// Drives the البانرات tab of `/console/promos` (FC16) — same
/// reload-whole-list-after-mutation contract as `TaxonomyBoardBloc`,
/// including the up/down reorder shape.
class BannersBoardBloc extends Bloc<BannersBoardEvent, BannersBoardState> {
  BannersBoardBloc({
    required GetAllBanners getAllBanners,
    required CreateBanner createBanner,
    required UpdateBanner updateBanner,
    required SetBannerActive setBannerActive,
    required SwapBannerSort swapBannerSort,
    required DeleteBanner deleteBanner,
  })  : _getAllBanners = getAllBanners,
        _createBanner = createBanner,
        _updateBanner = updateBanner,
        _setBannerActive = setBannerActive,
        _swapBannerSort = swapBannerSort,
        _deleteBanner = deleteBanner,
        super(const BannersBoardState()) {
    on<BannersBoardStarted>(_onLoad);
    on<BannersBoardRetryRequested>(_onLoad);
    on<BannersBoardActiveToggled>(
      (e, emit) => _runAction(
        emit,
        () => _setBannerActive(id: e.id, value: e.value),
      ),
    );
    on<BannersBoardMoveRequested>(_onMove);
    on<BannersBoardCreateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _createBanner(
          imageUrl: e.imageUrl,
          targetType: e.targetType,
          targetId: e.targetId,
          targetShopId: e.targetShopId,
          startsAt: e.startsAt,
          endsAt: e.endsAt,
        ),
      ),
    );
    on<BannersBoardUpdateRequested>(
      (e, emit) => _runAction(emit, () => _updateBanner(e.banner)),
    );
    on<BannersBoardDeleteRequested>(
      (e, emit) => _runAction(emit, () => _deleteBanner(e.id)),
    );
  }

  final GetAllBanners _getAllBanners;
  final CreateBanner _createBanner;
  final UpdateBanner _updateBanner;
  final SetBannerActive _setBannerActive;
  final SwapBannerSort _swapBannerSort;
  final DeleteBanner _deleteBanner;

  Future<void> _onLoad(
    BannersBoardEvent event,
    Emitter<BannersBoardState> emit,
  ) async {
    emit(state.copyWith(status: BannersBoardStatus.loading));
    try {
      final banners = await _getAllBanners();
      emit(state.copyWith(status: BannersBoardStatus.loaded, banners: banners));
    } catch (_) {
      emit(state.copyWith(status: BannersBoardStatus.error));
    }
  }

  Future<void> _onMove(
    BannersBoardMoveRequested event,
    Emitter<BannersBoardState> emit,
  ) async {
    final banners = state.banners;
    final index = banners.indexWhere((b) => b.id == event.bannerId);
    if (index == -1) return;
    final neighborIndex = event.up ? index - 1 : index + 1;
    if (neighborIndex < 0 || neighborIndex >= banners.length) return;
    final a = banners[index];
    final b = banners[neighborIndex];
    await _runAction(
      emit,
      () => _swapBannerSort(aId: a.id, aSort: b.sort, bId: b.id, bSort: a.sort),
    );
  }

  Future<void> _runAction(
    Emitter<BannersBoardState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: false));
    try {
      await action();
      final banners = await _getAllBanners();
      emit(state.copyWith(
        status: BannersBoardStatus.loaded,
        actionBusy: false,
        banners: banners,
      ));
    } catch (_) {
      emit(state.copyWith(actionBusy: false, actionError: true));
    }
  }
}
