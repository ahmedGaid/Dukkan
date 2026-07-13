import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/search/arabic_fold.dart';
import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/shop/entities/shop.dart';

part 'shops_board_event.dart';
part 'shops_board_state.dart';

/// Drives the console shop board (`/console/shops`, FC7). Loads every shop
/// once (the marketplace is small — see `getAllShops` doc) and filters/
/// searches/paginates entirely client-side; a mutation on the detail page
/// (`ShopDetailBloc`) doesn't touch this bloc — reopening the board reloads.
class ShopsBoardBloc extends Bloc<ShopsBoardEvent, ShopsBoardState> {
  ShopsBoardBloc({required GetAllShops getAllShops})
      : _getAllShops = getAllShops,
        super(const ShopsBoardState()) {
    on<ShopsBoardStarted>(_onLoad);
    on<ShopsBoardRetryRequested>(_onLoad);
    on<ShopsBoardStatusFilterChanged>((event, emit) => emit(
          state.copyWith(statusFilter: event.status, visibleCount: 20),
        ));
    on<ShopsBoardSearchChanged>((event, emit) => emit(
          state.copyWith(query: event.query, visibleCount: 20),
        ));
    on<ShopsBoardLoadMoreRequested>((event, emit) {
      if (!state.hasMore) return;
      emit(state.copyWith(visibleCount: state.visibleCount + 20));
    });
  }

  final GetAllShops _getAllShops;

  Future<void> _onLoad(ShopsBoardEvent event, Emitter<ShopsBoardState> emit) async {
    emit(state.copyWith(status: ShopsBoardStatus.loading));
    try {
      final shops = await _getAllShops();
      emit(state.copyWith(status: ShopsBoardStatus.loaded, allShops: shops));
    } catch (_) {
      emit(state.copyWith(status: ShopsBoardStatus.error));
    }
  }
}
