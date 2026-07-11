import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/collections/entities/shop_collection.dart';
import '../../../domain/collections/usecases/watch_collections.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/usecases/watch_products_by_shop.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shop.dart';

part 'products_event.dart';
part 'products_state.dart';

/// Drives one shop page. Subscribes to two realtime streams — the shop itself
/// ([WatchShop], for the header) and its catalog ([WatchProductsByShop]) — and
/// holds the in-shop category filter locally, mirroring [ShopsBloc] on Home so
/// tapping a category re-derives the visible grid without re-hitting the stream.
/// The page reads `loaded` only once BOTH streams have delivered their first
/// value, so the header and grid appear together (no half-built flash).
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({
    required String shopId,
    required WatchShop watchShop,
    required WatchProductsByShop watchProductsByShop,
    required WatchCollections watchCollections,
    String? initialCategory,
  })  : _shopId = shopId,
        _watchShop = watchShop,
        _watchProductsByShop = watchProductsByShop,
        _watchCollections = watchCollections,
        _pendingInitialCategory = initialCategory,
        super(const ProductsState()) {
    on<ProductsStarted>(_onStarted);
    on<ProductsRetryRequested>(_onStarted);
    on<ProductsCategorySelected>(_onCategorySelected);
    on<ProductsCollectionSelected>(_onCollectionSelected);
    on<_ShopArrived>(_onShopArrived);
    on<_ProductsArrived>(_onProductsArrived);
    on<_ProductsFailed>(_onFailed);
    on<_CollectionsArrived>(_onCollectionsArrived);
  }

  final String _shopId;
  final WatchShop _watchShop;
  final WatchProductsByShop _watchProductsByShop;
  final WatchCollections _watchCollections;

  /// Home category carried through navigation (M5) — applied once, on the
  /// catalog's first arrival, then cleared so a later re-selection (or a
  /// catalog update dropping a stale filter) behaves like any other pick.
  String? _pendingInitialCategory;

  StreamSubscription<Shop>? _shopSub;
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<ShopCollection>>? _collectionsSub;
  bool _shopReady = false;
  bool _productsReady = false;

  Future<void> _onStarted(
    ProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(status: ProductsStatus.loading));
    _shopReady = false;
    _productsReady = false;
    await _shopSub?.cancel();
    await _productsSub?.cancel();
    await _collectionsSub?.cancel();
    _shopSub = _watchShop(_shopId).listen(
      (shop) => add(_ShopArrived(shop)),
      onError: (Object error) => add(_ProductsFailed(error)),
    );
    _productsSub = _watchProductsByShop(_shopId).listen(
      (products) => add(_ProductsArrived(products)),
      onError: (Object error) => add(_ProductsFailed(error)),
    );
    // Non-critical to this page's load status — a failure here is swallowed
    // rather than surfaced, so the shop page never breaks over an optional
    // filter row.
    _collectionsSub = _watchCollections(_shopId).listen(
      (collections) => add(_CollectionsArrived(collections)),
      onError: (_) {},
    );
  }

  void _onShopArrived(_ShopArrived event, Emitter<ProductsState> emit) {
    _shopReady = true;
    emit(state.copyWith(shop: event.shop, status: _readyStatus()));
  }

  void _onProductsArrived(_ProductsArrived event, Emitter<ProductsState> emit) {
    _productsReady = true;
    final categories = _categoriesOf(event.products);

    // A carried-over home category (M5) wins on the very first arrival, if it
    // actually matches a category in this shop; consumed once either way.
    final carried = _pendingInitialCategory;
    _pendingInitialCategory = null;
    final wanted = carried != null && categories.contains(carried)
        ? carried
        : state.selectedCategory;

    // A category the user had picked (or just carried in) may not be present
    // — drop the filter rather than show an empty grid for a stale pick.
    final stillValid = wanted != null && categories.contains(wanted);
    emit(state.copyWith(
      status: _readyStatus(),
      products: event.products,
      categories: categories,
      selectedCategory: stillValid ? wanted : null,
      clearCategory: !stillValid,
    ));
  }

  void _onFailed(_ProductsFailed event, Emitter<ProductsState> emit) {
    emit(state.copyWith(status: ProductsStatus.error));
  }

  void _onCategorySelected(
    ProductsCategorySelected event,
    Emitter<ProductsState> emit,
  ) {
    // Tapping the active category again clears the filter (toggle).
    final next =
        event.category == state.selectedCategory ? null : event.category;
    emit(state.copyWith(
      selectedCategory: next,
      clearCategory: next == null,
    ));
  }

  void _onCollectionsArrived(
    _CollectionsArrived event,
    Emitter<ProductsState> emit,
  ) {
    // A selected collection that just got deleted by the owner: drop the
    // filter rather than keep a chip selected that no longer exists.
    final ids = event.collections.map((c) => c.id);
    final selected = state.selectedCollectionId;
    final stillValid = selected != null && ids.contains(selected);
    emit(state.copyWith(
      collections: event.collections,
      selectedCollectionId: stillValid ? selected : null,
      clearCollection: !stillValid,
    ));
  }

  void _onCollectionSelected(
    ProductsCollectionSelected event,
    Emitter<ProductsState> emit,
  ) {
    // Tapping the active collection again clears the filter (toggle).
    final next = event.collectionId == state.selectedCollectionId
        ? null
        : event.collectionId;
    emit(state.copyWith(
      selectedCollectionId: next,
      clearCollection: next == null,
    ));
  }

  ProductsStatus _readyStatus() => _shopReady && _productsReady
      ? ProductsStatus.loaded
      : ProductsStatus.loading;

  /// The catalog's categories, first-seen order preserved (drives the filter).
  List<String> _categoriesOf(List<Product> products) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final p in products) {
      if (seen.add(p.category)) ordered.add(p.category);
    }
    return ordered;
  }

  @override
  Future<void> close() {
    _shopSub?.cancel();
    _productsSub?.cancel();
    _collectionsSub?.cancel();
    return super.close();
  }
}
