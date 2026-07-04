part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to all products + all shops (fired once on search-page open).
class SearchStarted extends SearchEvent {
  const SearchStarted();
}

/// Re-subscribe after an error (retry action).
class SearchRetryRequested extends SearchEvent {
  const SearchRetryRequested();
}

/// User edited the query (dispatched debounced from the field).
class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Internal: a new product snapshot arrived from the stream.
class _ProductsArrived extends SearchEvent {
  const _ProductsArrived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

/// Internal: a new shop snapshot arrived from the stream.
class _ShopsArrived extends SearchEvent {
  const _ShopsArrived(this.shops);

  final List<Shop> shops;

  @override
  List<Object?> get props => [shops];
}

/// Internal: either stream errored.
class _SearchFailed extends SearchEvent {
  const _SearchFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
