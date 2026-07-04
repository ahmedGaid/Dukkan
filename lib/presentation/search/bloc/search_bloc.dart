import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/search/arabic_fold.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/usecases/watch_all_products.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shops.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Drives global marketplace search. Subscribes to every product and every shop
/// (both realtime), then filters locally as the query changes — Arabic-folded,
/// so misspelled hamzas/ة/ي still match. A product surfaces when the query hits
/// its name, category, OR the name of the shop it belongs to (typing a دكان's
/// name lists its products). Debounce lives in the field; the bloc filters
/// synchronously so it stays pure and testable.
///
/// Like [ProductsBloc] on the shop page, `ready` is reached only once BOTH
/// streams have delivered their first value, so results never flash half-built.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required WatchAllProducts watchAllProducts,
    required WatchShops watchShops,
  })  : _watchAllProducts = watchAllProducts,
        _watchShops = watchShops,
        super(const SearchState()) {
    on<SearchStarted>(_onStarted);
    on<SearchRetryRequested>(_onStarted);
    on<SearchQueryChanged>(_onQueryChanged);
    on<_ProductsArrived>(_onProductsArrived);
    on<_ShopsArrived>(_onShopsArrived);
    on<_SearchFailed>(_onFailed);
  }

  final WatchAllProducts _watchAllProducts;
  final WatchShops _watchShops;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<Shop>>? _shopsSub;
  bool _productsReady = false;
  bool _shopsReady = false;

  Future<void> _onStarted(SearchEvent event, Emitter<SearchState> emit) async {
    emit(state.copyWith(status: SearchStatus.loading));
    _productsReady = false;
    _shopsReady = false;
    await _productsSub?.cancel();
    await _shopsSub?.cancel();
    _productsSub = _watchAllProducts().listen(
      (products) => add(_ProductsArrived(products)),
      onError: (Object error) => add(_SearchFailed(error)),
    );
    _shopsSub = _watchShops().listen(
      (shops) => add(_ShopsArrived(shops)),
      onError: (Object error) => add(_SearchFailed(error)),
    );
  }

  void _onProductsArrived(_ProductsArrived event, Emitter<SearchState> emit) {
    _productsReady = true;
    _emitRecomputed(emit, products: event.products);
  }

  void _onShopsArrived(_ShopsArrived event, Emitter<SearchState> emit) {
    _shopsReady = true;
    _emitRecomputed(
      emit,
      shopsById: {for (final s in event.shops) s.id: s},
    );
  }

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    _emitRecomputed(emit, query: event.query);
  }

  void _onFailed(_SearchFailed event, Emitter<SearchState> emit) {
    emit(state.copyWith(status: SearchStatus.error));
  }

  /// Re-run the filter with whichever field changed and emit. Status becomes
  /// `ready` only when both streams have arrived at least once.
  void _emitRecomputed(
    Emitter<SearchState> emit, {
    String? query,
    List<Product>? products,
    Map<String, Shop>? shopsById,
  }) {
    final nextQuery = query ?? state.query;
    final nextProducts = products ?? state.products;
    final nextShops = shopsById ?? state.shopsById;
    final ready = _productsReady && _shopsReady;
    emit(state.copyWith(
      status: ready ? SearchStatus.ready : SearchStatus.loading,
      query: nextQuery,
      products: nextProducts,
      shopsById: nextShops,
      results: _filter(nextQuery, nextProducts, nextShops),
    ));
  }

  /// Products matching the folded query by their own name/category or their
  /// shop's name. Empty query → no results (the view shows the search prompt).
  static List<Product> _filter(
    String query,
    List<Product> products,
    Map<String, Shop> shopsById,
  ) {
    final q = normalizeSearch(query);
    if (q.isEmpty) return const [];
    return products.where((p) {
      final shop = shopsById[p.shopId];
      final haystacks = <String>[
        p.name,
        p.nameAr,
        p.category,
        if (shop != null) ...[shop.name, shop.nameAr],
      ];
      return haystacks.any((h) => normalizeSearch(h).contains(q));
    }).toList();
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    _shopsSub?.cancel();
    return super.close();
  }
}
