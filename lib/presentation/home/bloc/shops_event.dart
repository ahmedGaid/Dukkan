part of 'shops_bloc.dart';

sealed class ShopsEvent extends Equatable {
  const ShopsEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the shops feed (fired once on Home open).
class ShopsStarted extends ShopsEvent {
  const ShopsStarted();
}

/// Re-subscribe after an error (retry action).
class ShopsRetryRequested extends ShopsEvent {
  const ShopsRetryRequested();
}

/// User tapped a category tile — filters the visible shops. Passing the
/// already-selected category clears the filter.
class ShopsCategorySelected extends ShopsEvent {
  const ShopsCategorySelected(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

/// Internal: a new list arrived from the stream.
class _ShopsUpdated extends ShopsEvent {
  const _ShopsUpdated(this.shops);

  final List<Shop> shops;

  @override
  List<Object?> get props => [shops];
}

/// Internal: a new product list arrived — filtered to `isPromo` for the
/// carousel.
class _ShopsProductsUpdated extends ShopsEvent {
  const _ShopsProductsUpdated(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

/// Internal: a new active-banner list arrived (FC16 Task B) — non-critical,
/// never blocks `loaded` the way shops/products readiness does.
class _ShopsBannersUpdated extends ShopsEvent {
  const _ShopsBannersUpdated(this.banners);

  final List<PromoBanner> banners;

  @override
  List<Object?> get props => [banners];
}

/// Internal: the taxonomy list changed (console add/hide/reorder) — drives
/// the category grid directly, independent of shop coverage. Non-critical,
/// same as banners: a failure yields an empty list rather than an error state.
class _TaxonomyUpdated extends ShopsEvent {
  const _TaxonomyUpdated(this.categories);

  final List<Category> categories;

  @override
  List<Object?> get props => [categories];
}

/// Internal: the stream errored.
class _ShopsFailed extends ShopsEvent {
  const _ShopsFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
