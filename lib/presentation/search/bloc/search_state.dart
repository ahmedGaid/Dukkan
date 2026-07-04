part of 'search_bloc.dart';

enum SearchStatus { loading, ready, error }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.loading,
    this.query = '',
    this.products = const [],
    this.shopsById = const {},
    this.results = const [],
  });

  final SearchStatus status;

  /// The current (folded-on-compare) query text.
  final String query;

  /// Every product in the marketplace — the corpus [results] filters over.
  final List<Product> products;

  /// Shops keyed by id: supplies each result's shop name (subtitle) and lets a
  /// query match by shop name.
  final Map<String, Shop> shopsById;

  /// Products matching [query]. Empty while the query is blank (the view shows
  /// the search prompt), and empty on a genuine no-match (it shows no-results).
  final List<Product> results;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Product>? products,
    Map<String, Shop>? shopsById,
    List<Product>? results,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      products: products ?? this.products,
      shopsById: shopsById ?? this.shopsById,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [status, query, products, shopsById, results];
}
