part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the shop + its catalog (fired once on shop-page open).
class ProductsStarted extends ProductsEvent {
  const ProductsStarted();
}

/// Re-subscribe after an error (retry action).
class ProductsRetryRequested extends ProductsEvent {
  const ProductsRetryRequested();
}

/// User tapped an in-shop category — filters the visible grid. Passing the
/// already-selected category clears the filter.
class ProductsCategorySelected extends ProductsEvent {
  const ProductsCategorySelected(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

/// User tapped a collection chip (M7) — filters the visible grid, combined
/// with the category filter (AND). Passing the already-selected id clears it.
class ProductsCollectionSelected extends ProductsEvent {
  const ProductsCollectionSelected(this.collectionId);

  final String collectionId;

  @override
  List<Object?> get props => [collectionId];
}

/// Internal: a new shop snapshot arrived from the stream (header data).
class _ShopArrived extends ProductsEvent {
  const _ShopArrived(this.shop);

  final Shop shop;

  @override
  List<Object?> get props => [shop];
}

/// Internal: a new product list arrived from the stream.
class _ProductsArrived extends ProductsEvent {
  const _ProductsArrived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

/// Internal: either stream errored.
class _ProductsFailed extends ProductsEvent {
  const _ProductsFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: a new collections snapshot arrived (M7). Non-critical to the
/// page's own load status — a failure on this stream is swallowed upstream,
/// never surfaced as [ProductsStatus.error].
class _CollectionsArrived extends ProductsEvent {
  const _CollectionsArrived(this.collections);

  final List<ShopCollection> collections;

  @override
  List<Object?> get props => [collections];
}
