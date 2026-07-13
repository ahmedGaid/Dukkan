part of 'shops_board_bloc.dart';

sealed class ShopsBoardEvent extends Equatable {
  const ShopsBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads every shop (unfiltered; the board filters
/// and paginates client-side, the shop count is small).
class ShopsBoardStarted extends ShopsBoardEvent {
  const ShopsBoardStarted();
}

class ShopsBoardRetryRequested extends ShopsBoardEvent {
  const ShopsBoardRetryRequested();
}

/// Status filter chip changed. Null = الكل (all, minus deleted).
class ShopsBoardStatusFilterChanged extends ShopsBoardEvent {
  const ShopsBoardStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

/// Search field changed — Arabic-folded contains on name/nameAr, over the
/// already-loaded list (no re-fetch).
class ShopsBoardSearchChanged extends ShopsBoardEvent {
  const ShopsBoardSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Reveals the next slice of the already-loaded, already-filtered list.
class ShopsBoardLoadMoreRequested extends ShopsBoardEvent {
  const ShopsBoardLoadMoreRequested();
}
