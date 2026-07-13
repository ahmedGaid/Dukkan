part of 'products_board_bloc.dart';

enum ProductsBoardStatus { loading, loaded, error }

class ProductsBoardState extends Equatable {
  const ProductsBoardState({
    this.status = ProductsBoardStatus.loading,
    this.products = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.shops = const [],
    this.shopId,
    this.category,
    this.subcategoryId,
    this.stockStatus,
    this.isPromo,
    this.deletedOnly = false,
    this.searchQuery = '',
    this.searchPool,
    this.searching = false,
    this.selected = const {},
    this.bulkBusy = false,
    this.actionError,
  });

  final ProductsBoardStatus status;
  final List<Product> products;
  final bool hasMore;
  final bool loadingMore;

  /// Loaded once at board open — backs the shop-dropdown filter.
  final List<Shop> shops;

  final String? shopId;
  final String? category;
  final String? subcategoryId;
  final String? stockStatus;
  final bool? isPromo;
  final bool deletedOnly;

  final String searchQuery;

  /// Null = normal paginated [products]; non-null = every product matching
  /// the active filters, fold-searched client-side by [searchQuery] on every
  /// keystroke without a re-fetch (see `ProductsBoardBloc` doc).
  final List<Product>? searchPool;
  final bool searching;

  final Set<String> selected;
  final bool bulkBusy;

  /// Set for one snackbar tick after a row/bulk action fails; cleared by the
  /// next state change.
  final String? actionError;

  bool get isSearching => searchPool != null;

  /// What the list widget should actually render.
  List<Product> get visibleProducts {
    final pool = searchPool;
    if (pool == null) return products;
    final q = normalizeSearch(searchQuery);
    if (q.isEmpty) return pool;
    return pool
        .where((p) =>
            normalizeSearch(p.name).contains(q) || normalizeSearch(p.nameAr).contains(q))
        .toList(growable: false);
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    final pool = searchPool;
    if (pool != null) {
      for (final p in pool) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  static const _unset = Object();

  ProductsBoardState copyWith({
    ProductsBoardStatus? status,
    List<Product>? products,
    bool? hasMore,
    bool? loadingMore,
    List<Shop>? shops,
    Object? shopId = _unset,
    Object? category = _unset,
    Object? subcategoryId = _unset,
    Object? stockStatus = _unset,
    Object? isPromo = _unset,
    bool? deletedOnly,
    String? searchQuery,
    Object? searchPool = _unset,
    bool? searching,
    Set<String>? selected,
    bool? bulkBusy,
    Object? actionError = _unset,
  }) {
    return ProductsBoardState(
      status: status ?? this.status,
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      shops: shops ?? this.shops,
      shopId: shopId == _unset ? this.shopId : shopId as String?,
      category: category == _unset ? this.category : category as String?,
      subcategoryId:
          subcategoryId == _unset ? this.subcategoryId : subcategoryId as String?,
      stockStatus: stockStatus == _unset ? this.stockStatus : stockStatus as String?,
      isPromo: isPromo == _unset ? this.isPromo : isPromo as bool?,
      deletedOnly: deletedOnly ?? this.deletedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      searchPool: searchPool == _unset ? this.searchPool : searchPool as List<Product>?,
      searching: searching ?? this.searching,
      selected: selected ?? this.selected,
      bulkBusy: bulkBusy ?? this.bulkBusy,
      actionError: actionError == _unset ? this.actionError : actionError as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        hasMore,
        loadingMore,
        shops,
        shopId,
        category,
        subcategoryId,
        stockStatus,
        isPromo,
        deletedOnly,
        searchQuery,
        searchPool,
        searching,
        selected,
        bulkBusy,
        actionError,
      ];
}
