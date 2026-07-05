import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/favorites/entities/favorites.dart';
import '../../../domain/favorites/usecases/watch_favorites.dart';
import '../../auth/bloc/auth_bloc.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// App-lifetime favorites feed (registered as a lazy singleton, like
/// [AuthBloc]/`CartBloc` — one heart-state feed reused across Home, Shop,
/// Search, product detail, and the Favorites tab). Toggling itself is NOT a
/// bloc event: `FavoriteButton` calls `ToggleFavoriteShop`/`ToggleFavoriteProduct`
/// directly (same direct-usecase-call pattern as the S3 order desk), and this
/// bloc's realtime watch reflects the change back.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({required AuthBloc authBloc, required WatchFavorites watchFavorites})
      : _authBloc = authBloc,
        _watchFavorites = watchFavorites,
        super(const FavoritesState()) {
    on<_FavoritesAuthChanged>(_onAuthChanged);
    on<_FavoritesUpdated>(_onUpdated);
    on<_FavoritesFailed>(_onFailed);

    _authSub = _authBloc.stream.listen(
      (state) => add(_FavoritesAuthChanged(state.user?.uid)),
    );
    final initialUid = _authBloc.state.user?.uid;
    if (initialUid != null) add(_FavoritesAuthChanged(initialUid));
  }

  final AuthBloc _authBloc;
  final WatchFavorites _watchFavorites;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Favorites>? _favSub;
  String? _uid;

  Future<void> _onAuthChanged(
    _FavoritesAuthChanged event,
    Emitter<FavoritesState> emit,
  ) async {
    if (event.uid == _uid) return;
    _uid = event.uid;
    await _favSub?.cancel();

    final uid = event.uid;
    if (uid == null) {
      emit(const FavoritesState());
      return;
    }
    emit(state.copyWith(status: FavoritesStatus.loading));
    _favSub = _watchFavorites(uid).listen(
      (favorites) => add(_FavoritesUpdated(favorites)),
      onError: (Object error) => add(_FavoritesFailed(error)),
    );
  }

  void _onUpdated(_FavoritesUpdated event, Emitter<FavoritesState> emit) {
    emit(state.copyWith(status: FavoritesStatus.loaded, favorites: event.favorites));
  }

  void _onFailed(_FavoritesFailed event, Emitter<FavoritesState> emit) {
    emit(state.copyWith(status: FavoritesStatus.error));
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    _favSub?.cancel();
    return super.close();
  }
}
