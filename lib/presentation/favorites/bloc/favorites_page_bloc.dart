import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/favorites/entities/favorites.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/usecases/watch_all_products.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shops.dart';
import 'favorites_bloc.dart';

part 'favorites_page_event.dart';
part 'favorites_page_state.dart';

/// Drives the Favorites tab: combines [FavoritesBloc]'s id sets with the full
/// shops/products feeds (same realtime sources `ShopsBloc`/`SearchBloc` use)
/// and filters locally, like [SearchBloc] combining products+shops. `loaded`
/// is reached only once all three sources have delivered a first value.
class FavoritesPageBloc extends Bloc<FavoritesPageEvent, FavoritesPageState> {
  FavoritesPageBloc({
    required FavoritesBloc favoritesBloc,
    required WatchShops watchShops,
    required WatchAllProducts watchAllProducts,
  })  : _favoritesBloc = favoritesBloc,
        _watchShops = watchShops,
        _watchAllProducts = watchAllProducts,
        super(const FavoritesPageState()) {
    on<FavoritesPageStarted>(_onStarted);
    on<FavoritesPageRetryRequested>(_onStarted);
    on<_FavoriteIdsArrived>(_onIdsArrived);
    on<_ShopsArrived>(_onShopsArrived);
    on<_ProductsArrived>(_onProductsArrived);
    on<_FavoritesPageFailed>(_onFailed);
  }

  final FavoritesBloc _favoritesBloc;
  final WatchShops _watchShops;
  final WatchAllProducts _watchAllProducts;

  StreamSubscription<FavoritesState>? _idsSub;
  StreamSubscription<List<Shop>>? _shopsSub;
  StreamSubscription<List<Product>>? _productsSub;

  Favorites _favorites = const Favorites.empty();
  List<Shop> _shops = const [];
  List<Product> _products = const [];
  bool _idsReady = false;
  bool _shopsReady = false;
  bool _productsReady = false;

  Future<void> _onStarted(
    FavoritesPageEvent event,
    Emitter<FavoritesPageState> emit,
  ) async {
    emit(state.copyWith(status: FavoritesPageStatus.loading));
    _idsReady = false;
    _shopsReady = false;
    _productsReady = false;
    await _idsSub?.cancel();
    await _shopsSub?.cancel();
    await _productsSub?.cancel();

    _idsSub = _favoritesBloc.stream.listen(
      (s) => add(_FavoriteIdsArrived(s.favorites)),
    );
    if (_favoritesBloc.state.status != FavoritesStatus.loading) {
      add(_FavoriteIdsArrived(_favoritesBloc.state.favorites));
    }
    _shopsSub = _watchShops().listen(
      (shops) => add(_ShopsArrived(shops)),
      onError: (Object error) => add(_FavoritesPageFailed(error)),
    );
    _productsSub = _watchAllProducts().listen(
      (products) => add(_ProductsArrived(products)),
      onError: (Object error) => add(_FavoritesPageFailed(error)),
    );
  }

  void _onIdsArrived(_FavoriteIdsArrived event, Emitter<FavoritesPageState> emit) {
    _idsReady = true;
    _favorites = event.favorites;
    _emitRecomputed(emit);
  }

  void _onShopsArrived(_ShopsArrived event, Emitter<FavoritesPageState> emit) {
    _shopsReady = true;
    _shops = event.shops;
    _emitRecomputed(emit);
  }

  void _onProductsArrived(_ProductsArrived event, Emitter<FavoritesPageState> emit) {
    _productsReady = true;
    _products = event.products;
    _emitRecomputed(emit);
  }

  void _onFailed(_FavoritesPageFailed event, Emitter<FavoritesPageState> emit) {
    emit(state.copyWith(status: FavoritesPageStatus.error));
  }

  void _emitRecomputed(Emitter<FavoritesPageState> emit) {
    final ready = _idsReady && _shopsReady && _productsReady;
    emit(state.copyWith(
      status: ready ? FavoritesPageStatus.loaded : FavoritesPageStatus.loading,
      favoriteShops: _shops.where((s) => _favorites.hasShop(s.id)).toList(),
      favoriteProducts:
          _products.where((p) => _favorites.hasProduct(p.id)).toList(),
      shopsById: {for (final s in _shops) s.id: s},
    ));
  }

  @override
  Future<void> close() {
    _idsSub?.cancel();
    _shopsSub?.cancel();
    _productsSub?.cancel();
    return super.close();
  }
}
