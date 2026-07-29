import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/product/entities/product.dart';
import '../../../domain/product/usecases/watch_all_products.dart';
import '../../../domain/promos/entities/promo_banner.dart';
import '../../../domain/promos/usecases/watch_active_banners.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shops.dart';
import '../widgets/promo_carousel.dart';

part 'shops_event.dart';
part 'shops_state.dart';

/// Drives the customer Home. Subscribes to [WatchShops] (realtime online, one
/// cached snapshot offline) and holds the selected category filter locally, so
/// tapping a category re-derives the visible list without re-hitting the stream.
/// Also subscribes to [WatchAllProducts] to feed the promo/featured carousel
/// slots (P1/FC16) — `loaded` is reached only once both feeds have delivered a
/// first value, matching [SearchBloc]'s dual-stream readiness. [WatchActiveBanners]
/// is a third, non-critical stream (FC16 Task B) — mirrors [ProductsBloc]'s
/// `WatchCollections` addition: a failure is swallowed, never blocks `loaded`.
class ShopsBloc extends Bloc<ShopsEvent, ShopsState> {
  ShopsBloc({
    required WatchShops watchShops,
    required WatchAllProducts watchAllProducts,
    required WatchActiveBanners watchActiveBanners,
  })  : _watchShops = watchShops,
        _watchAllProducts = watchAllProducts,
        _watchActiveBanners = watchActiveBanners,
        super(const ShopsState()) {
    on<ShopsStarted>(_onStarted);
    on<ShopsCategorySelected>(_onCategorySelected);
    on<ShopsRetryRequested>(_onStarted);
    on<_ShopsUpdated>(_onUpdated);
    on<_ShopsProductsUpdated>(_onProductsUpdated);
    on<_ShopsBannersUpdated>(_onBannersUpdated);
    on<_ShopsFailed>(_onFailed);
  }

  final WatchShops _watchShops;
  final WatchAllProducts _watchAllProducts;
  final WatchActiveBanners _watchActiveBanners;
  StreamSubscription<List<Shop>>? _sub;
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<PromoBanner>>? _bannersSub;
  bool _shopsReady = false;
  bool _productsReady = false;

  Future<void> _onStarted(ShopsEvent event, Emitter<ShopsState> emit) async {
    emit(state.copyWith(status: ShopsStatus.loading));
    _shopsReady = false;
    _productsReady = false;
    await _sub?.cancel();
    await _productsSub?.cancel();
    await _bannersSub?.cancel();
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
  }

  void _onUpdated(_ShopsUpdated event, Emitter<ShopsState> emit) {
    _shopsReady = true;
    // A category the user had picked may vanish if that shop left the feed —
    // drop the filter rather than show an empty list for a stale selection.
    final categories = _categoriesOf(event.shops);
    final stillValid = state.selectedCategory != null &&
        categories.contains(state.selectedCategory);
    emit(state.copyWith(
      status: _readyStatus,
      shops: event.shops,
      categories: categories,
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

  /// Union of every shop's categories, first-seen order preserved.
  List<String> _categoriesOf(List<Shop> shops) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final shop in shops) {
      for (final c in shop.categories) {
        if (seen.add(c)) ordered.add(c);
      }
    }
    return ordered;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _productsSub?.cancel();
    _bannersSub?.cancel();
    return super.close();
  }
}
