part of 'products_board_bloc.dart';

sealed class ProductsBoardEvent extends Equatable {
  const ProductsBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads the shop dropdown list plus the first
/// product page.
class ProductsBoardStarted extends ProductsBoardEvent {
  const ProductsBoardStarted();
}

class ProductsBoardRetryRequested extends ProductsBoardEvent {
  const ProductsBoardRetryRequested();
}

/// A filter dropdown/toggle changed — the view always resends every filter's
/// current value (null = "all" for that filter), mirroring `UsersFilterChanged`.
/// Clears search and reloads the first page.
class ProductsBoardFilterChanged extends ProductsBoardEvent {
  const ProductsBoardFilterChanged({
    this.shopId,
    this.category,
    this.subcategoryId,
    this.stockStatus,
    this.isPromo,
    this.deletedOnly = false,
  });

  final String? shopId;
  final String? category;
  final String? subcategoryId;
  final String? stockStatus;
  final bool? isPromo;
  final bool deletedOnly;

  @override
  List<Object?> get props =>
      [shopId, category, subcategoryId, stockStatus, isPromo, deletedOnly];
}

/// Appends the next page (cursor = the last loaded row's id).
class ProductsBoardLoadMoreRequested extends ProductsBoardEvent {
  const ProductsBoardLoadMoreRequested();
}

/// The search field changed. The first non-empty keystroke fetches every
/// product matching the current filters (unpaginated); every keystroke after
/// that just re-folds the already-fetched pool — see `ProductsBoardState.visibleProducts`.
class ProductsBoardSearchChanged extends ProductsBoardEvent {
  const ProductsBoardSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ProductSelectionToggled extends ProductsBoardEvent {
  const ProductSelectionToggled(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class ProductsBoardSelectionCleared extends ProductsBoardEvent {
  const ProductsBoardSelectionCleared();
}

class ProductsBoardSoftDeleteRequested extends ProductsBoardEvent {
  const ProductsBoardSoftDeleteRequested(this.productId, this.actorUid);

  final String productId;
  final String actorUid;

  @override
  List<Object?> get props => [productId, actorUid];
}

class ProductsBoardRestoreRequested extends ProductsBoardEvent {
  const ProductsBoardRestoreRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class ProductsBoardDuplicateRequested extends ProductsBoardEvent {
  const ProductsBoardDuplicateRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class ProductsBoardHardDeleteRequested extends ProductsBoardEvent {
  const ProductsBoardHardDeleteRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

/// Bulk price change over the current selection — exactly one of
/// [percentBps] (10000 = 100%, signed) or [fixedDeltaMinor] (signed piasters)
/// is set. New price is round-half-up (percent) or a floor-at-zero add
/// (fixed) per product — see `ProductsBoardBloc._priceAfterBulkChange`.
class ProductsBoardBulkPriceRequested extends ProductsBoardEvent {
  const ProductsBoardBulkPriceRequested({this.percentBps, this.fixedDeltaMinor});

  final int? percentBps;
  final int? fixedDeltaMinor;

  @override
  List<Object?> get props => [percentBps, fixedDeltaMinor];
}

class ProductsBoardBulkStockRequested extends ProductsBoardEvent {
  const ProductsBoardBulkStockRequested(this.status);

  final StockStatus status;

  @override
  List<Object?> get props => [status];
}

class ProductsBoardBulkPromoRequested extends ProductsBoardEvent {
  const ProductsBoardBulkPromoRequested(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class ProductsBoardBulkFeaturedRequested extends ProductsBoardEvent {
  const ProductsBoardBulkFeaturedRequested(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class ProductsBoardBulkCategoryRequested extends ProductsBoardEvent {
  const ProductsBoardBulkCategoryRequested({
    required this.category,
    required this.subcategoryId,
  });

  final String category;
  final String subcategoryId;

  @override
  List<Object?> get props => [category, subcategoryId];
}
