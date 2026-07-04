import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shops.dart';

part 'shops_event.dart';
part 'shops_state.dart';

/// Drives the customer Home. Subscribes to [WatchShops] (realtime online, one
/// cached snapshot offline) and holds the selected category filter locally, so
/// tapping a category re-derives the visible list without re-hitting the stream.
class ShopsBloc extends Bloc<ShopsEvent, ShopsState> {
  ShopsBloc({required WatchShops watchShops})
      : _watchShops = watchShops,
        super(const ShopsState()) {
    on<ShopsStarted>(_onStarted);
    on<ShopsCategorySelected>(_onCategorySelected);
    on<ShopsRetryRequested>(_onStarted);
    on<_ShopsUpdated>(_onUpdated);
    on<_ShopsFailed>(_onFailed);
  }

  final WatchShops _watchShops;
  StreamSubscription<List<Shop>>? _sub;

  Future<void> _onStarted(ShopsEvent event, Emitter<ShopsState> emit) async {
    emit(state.copyWith(status: ShopsStatus.loading));
    await _sub?.cancel();
    _sub = _watchShops().listen(
      (shops) => add(_ShopsUpdated(shops)),
      onError: (Object error) => add(_ShopsFailed(error)),
    );
  }

  void _onUpdated(_ShopsUpdated event, Emitter<ShopsState> emit) {
    // A category the user had picked may vanish if that shop left the feed —
    // drop the filter rather than show an empty list for a stale selection.
    final categories = _categoriesOf(event.shops);
    final stillValid = state.selectedCategory != null &&
        categories.contains(state.selectedCategory);
    emit(state.copyWith(
      status: ShopsStatus.loaded,
      shops: event.shops,
      categories: categories,
      selectedCategory: stillValid ? state.selectedCategory : null,
      clearCategory: !stillValid,
    ));
  }

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
    return super.close();
  }
}
