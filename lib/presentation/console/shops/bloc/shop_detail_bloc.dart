import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/get_shop_by_id.dart';
import '../../../../domain/admin/usecases/restore_shop.dart';
import '../../../../domain/admin/usecases/set_shop_featured.dart';
import '../../../../domain/admin/usecases/set_shop_status.dart';
import '../../../../domain/admin/usecases/set_shop_verified.dart';
import '../../../../domain/admin/usecases/soft_delete_shop.dart';
import '../../../../domain/admin/usecases/transfer_shop_ownership.dart';
import '../../../../domain/admin/usecases/update_shop_details.dart';
import '../../../../domain/shop/entities/shop.dart';

part 'shop_detail_event.dart';
part 'shop_detail_state.dart';

/// Drives the console shop detail page (`/console/shops/:id`, FC7). Every
/// mutation is Firestore-direct + best-effort audit (see
/// `AdminShopsRepositoryImpl`) except [ShopDetailTransferRequested], which is
/// Worker-routed; after each one succeeds this reloads the shop by id so the
/// page always shows the post-mutation truth, not an optimistic guess
/// (mirrors `UserDetailBloc`).
class ShopDetailBloc extends Bloc<ShopDetailEvent, ShopDetailState> {
  ShopDetailBloc({
    required Shop seed,
    required String actorUid,
    required GetShopById getShopById,
    required SetShopStatus setShopStatus,
    required SetShopFeatured setShopFeatured,
    required SetShopVerified setShopVerified,
    required UpdateShopDetails updateShopDetails,
    required SoftDeleteShop softDeleteShop,
    required RestoreShop restoreShop,
    required TransferShopOwnership transferShopOwnership,
  })  : _actorUid = actorUid,
        _getShopById = getShopById,
        _setShopStatus = setShopStatus,
        _setShopFeatured = setShopFeatured,
        _setShopVerified = setShopVerified,
        _updateShopDetails = updateShopDetails,
        _softDeleteShop = softDeleteShop,
        _restoreShop = restoreShop,
        _transferShopOwnership = transferShopOwnership,
        super(ShopDetailState(shop: seed)) {
    on<ShopDetailSetStatusRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setShopStatus(shopId: state.shop.id, status: e.status, reason: e.reason),
      ),
    );
    on<ShopDetailSetFeaturedRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setShopFeatured(shopId: state.shop.id, value: e.value),
      ),
    );
    on<ShopDetailSetVerifiedRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setShopVerified(shopId: state.shop.id, value: e.value),
      ),
    );
    on<ShopDetailUpdateDetailsRequested>(
      (e, emit) => _runAction(
        emit,
        () => _updateShopDetails(
          shopId: state.shop.id,
          name: e.name,
          nameAr: e.nameAr,
          address: e.address,
          isOpen: e.isOpen,
          logoUrl: e.logoUrl,
          hoursNote: e.hoursNote,
        ),
      ),
    );
    on<ShopDetailSoftDeleteRequested>(
      (e, emit) => _runAction(
        emit,
        () => _softDeleteShop(shopId: state.shop.id, actorUid: _actorUid),
      ),
    );
    on<ShopDetailRestoreRequested>(
      (e, emit) => _runAction(emit, () => _restoreShop(state.shop.id)),
    );
    on<ShopDetailTransferRequested>(_onTransfer);
  }

  final String _actorUid;
  final GetShopById _getShopById;
  final SetShopStatus _setShopStatus;
  final SetShopFeatured _setShopFeatured;
  final SetShopVerified _setShopVerified;
  final UpdateShopDetails _updateShopDetails;
  final SoftDeleteShop _softDeleteShop;
  final RestoreShop _restoreShop;
  final TransferShopOwnership _transferShopOwnership;

  /// Runs one Firestore-direct mutation; on success reloads the shop by id so
  /// the page reflects the real post-mutation state. On failure, surfaces
  /// [ShopDetailState.actionError] for a snackbar; the page's data stays as-is.
  Future<void> _runAction(
    Emitter<ShopDetailState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: null));
    try {
      await action();
      final reloaded = await _getShopById(state.shop.id);
      emit(state.copyWith(actionBusy: false, shop: reloaded ?? state.shop));
    } catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: e.toString()));
    }
  }

  Future<void> _onTransfer(
    ShopDetailTransferRequested event,
    Emitter<ShopDetailState> emit,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: null));
    try {
      final result = await _transferShopOwnership(
        shopId: state.shop.id,
        newOwnerUid: event.newOwnerUid,
      );
      final reloaded = await _getShopById(state.shop.id);
      emit(state.copyWith(
        actionBusy: false,
        shop: reloaded ?? state.shop,
        transferOldOwnerStillOwnerRole: result['oldOwnerStillOwnerRole'] == true,
      ));
    } catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: e.toString()));
    }
  }
}
