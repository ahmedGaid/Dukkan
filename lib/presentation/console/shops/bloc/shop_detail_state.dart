part of 'shop_detail_bloc.dart';

class ShopDetailState extends Equatable {
  const ShopDetailState({
    required this.shop,
    this.actionBusy = false,
    this.actionError,
    this.transferOldOwnerStillOwnerRole = false,
  });

  final Shop shop;

  /// True while any mutation is in flight — the page disables its buttons.
  final bool actionBusy;

  /// The last mutation's technical failure code, or null if it succeeded /
  /// none has run yet. The page's `BlocListener` watches `actionBusy`
  /// transitioning true → false and reads this to decide the snackbar.
  final String? actionError;

  /// Set after a successful transfer when the OLD owner still carries
  /// `role: owner` with no shop left — the page shows a hint to also update
  /// their persona role via user management (Session 6), a manual step.
  final bool transferOldOwnerStillOwnerRole;

  static const _unset = Object();

  ShopDetailState copyWith({
    Shop? shop,
    bool? actionBusy,
    Object? actionError = _unset,
    bool? transferOldOwnerStillOwnerRole,
  }) {
    return ShopDetailState(
      shop: shop ?? this.shop,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError == _unset ? this.actionError : actionError as String?,
      transferOldOwnerStillOwnerRole:
          transferOldOwnerStillOwnerRole ?? this.transferOldOwnerStillOwnerRole,
    );
  }

  @override
  List<Object?> get props =>
      [shop, actionBusy, actionError, transferOldOwnerStillOwnerRole];
}
