import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/product/entities/product.dart';
import '../../../domain/product/usecases/watch_all_products.dart';
import '../../../domain/promos/entities/promo_banner.dart';
import '../../../domain/promos/usecases/watch_active_banners.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shops.dart';
import '../../../domain/taxonomy/entities/category.dart';
import '../../../domain/taxonomy/usecases/watch_taxonomy.dart';
import '../widgets/promo_carousel.dart';

part 'shops_event.dart';
part 'shops_state.dart';

/// Drives the customer Home. Subscribes to [WatchShops] (realtime online, one
/// cached snapshot offline) and holds the selected category filter locally, so
/// tapping a category re-derives the visible list without re-hitting the stream.
/// Also subscribes to [WatchAllProducts] to feed the promo/featured carousel
/// slots (P1/FC16) — `loaded` is reached only once both feeds have delivered a
/// first value, matching [SearchBloc]'s dual-stream readiness. [WatchActiveBanners]
/// and [WatchTaxonomy] are non-critical streams (the category grid hides
/// itself when empty, same as the carousel) — mirrors [ProductsBloc]'s
/// `WatchCollections` addition: a failure is swallowed, never blocks `loaded`.
class ShopsBloc extends Bloc<ShopsEvent, ShopsState> {
  ShopsBloc({
    required WatchShops watchShops,
    required WatchAllProducts watchAllProducts,
    required WatchActiveBanners watchActiveBanners,
    required WatchTaxonomy watchTaxonomy,
  })  : _watchShops = watchShops,
        _watchAllProducts = watchAllProducts,
        _watchActiveBanners = watchActiveBanners,
        _watchTaxonomy = watchTaxonomy,
        super(const ShopsState()) {
    on<ShopsStarted>(_onStarted);
    on<ShopsCategorySelected>(_onCategorySelected);
    on<ShopsRetryRequested>(_onStarted);
    on<_ShopsUpdated>(_onUpdated);
    on<_ShopsProductsUpdated>(_onProductsUpdated);
    on<_ShopsBannersUpdated>(_onBannersUpdated);
    on<_TaxonomyUpdated>(_onTaxonomyUpdated);
    on<_ShopsFailed>(_onFailed);
  }

  final WatchShops _watchShops;
  final WatchAllProducts _watchAllProducts;
  final WatchActiveBanners _watchActiveBanners;
  final WatchTaxonomy _watchTaxonomy;
  StreamSubscription<List<Shop>>? _sub;
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<PromoBanner>>? _bannersSub;
  StreamSubscription<List<Category>>? _taxonomySub;
  bool _shopsReady = false;
  bool _productsReady = false;

  Future<void> _onStarted(ShopsEvent event, Emitter<ShopsState> emit) async {
    emit(state.copyWith(status: ShopsStatus.loading));
    _shopsReady = false;
    _productsReady = false;
    await _sub?.cancel();
    await _productsSub?.cancel();
    await _bannersSub?.cancel();
    await _taxonomySub?.cancel();
    _sub = _watchShops().listen(
      (shops) => add(_ShopsUpdated(shops)),
      onError: (Object error) => add(_ShopsFailed(error)),
    );
    _productsSub = _watchAllProducts().listen(
      (products) => add(_ShopsProductsUpdated(products)),
      onError: (Object error) => add(_ShopsFailed(error)),
    );
    _bannersSub = _watchActiveBanners().listen(
      (banners) => add(_ShopsBannersUpdated(banners)),
      onError: (_) => add(const _ShopsBannersUpdated([])),
    );
    _taxonomySub = _watchTaxonomy().listen(
      (categories) => add(_TaxonomyUpdated(categories)),
      onError: (_) => add(const _TaxonomyUpdated([])),
    );
  }

  void _onUpdated(_ShopsUpdated event, Emitter<ShopsState> emit) {
    _shopsReady = true;
    emit(state.copyWith(status: _readyStatus, shops: event.shops));
  }

  void _onTaxonomyUpdated(_TaxonomyUpdated event, Emitter<ShopsState> emit) {
    // A category the founder had selected may have been hidden/deleted —
    // drop the filter rather than show an empty list for a stale selection.
    final stillValid = state.selectedCategory != null &&
        event.categories.any((c) => c.id == state.selectedCategory);
    emit(state.copyWith(
      categories: event.categories,
      selectedCategory: stillValid ? state.selectedCategory : null,
      clearCategory: !stillValid,
    ));
  }

  void _onProductsUpdated(_ShopsProductsUpdated event, Emitter<ShopsState> emit) {
    _productsReady = true;
    emit(state.copyWith(
      status: _readyStatus,
      promoProducts: event.products.where((p) => p.isPromo).take(8).toList(),
      featuredProducts:
          event.products.where((p) => p.isFeatured).take(6).toList(),
    ));
  }

  void _onBannersUpdated(_ShopsBannersUpdated event, Emitter<ShopsState> emit) {
    emit(state.copyWith(banners: event.banners));
  }

  ShopsStatus get _readyStatus =>
      _shopsReady && _productsReady ? ShopsStatus.loaded : ShopsStatus.loading;

  void _onFailed(_ShopsFailed event, Emitter<ShopsState> emit) {
    emit(state.copyWith(status: ShopsStatus.error));
  }

  void _onCategorySelected(
    ShopsCategorySelected event,
    Emitter<ShopsState> emit,
  ) {
    // Tapping the active category again clears the filter (toggle).
    final next =
        event.category == state.selectedCategory ? null : event.category;
    emit(state.copyWith(
      selectedCategory: next,
      clearCategory: next == null,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _productsSub?.cancel();
    _bannersSub?.cancel();
    _taxonomySub?.cancel();
    return super.close();
  }
}
