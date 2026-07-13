import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/search/arabic_fold.dart';
import '../../../../domain/admin/usecases/bulk_update_products.dart';
import '../../../../domain/admin/usecases/duplicate_product.dart';
import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/admin/usecases/get_products.dart';
import '../../../../domain/admin/usecases/hard_delete_product.dart';
import '../../../../domain/admin/usecases/restore_product.dart';
import '../../../../domain/admin/usecases/search_products.dart';
import '../../../../domain/admin/usecases/soft_delete_product.dart';
import '../../../../domain/product/entities/product.dart';
import '../../../../domain/product/entities/stock_status.dart';
import '../../../../domain/shop/entities/shop.dart';

part 'products_board_event.dart';
part 'products_board_state.dart';

/// Drives the console product board (`/console/products`, FC8). Filters run
/// as real Firestore `where` clauses with cursor pagination (25/page, see
/// `AdminProductsRemoteDataSource`); the Arabic-folded name search instead
/// fetches every product matching the active filters once and re-folds it
/// client-side per keystroke — the same "search over what's already loaded"
/// tradeoff `UsersBloc` makes, just against a filter-bounded pool instead of
/// the current page. Row/bulk mutations reload the current view afterward so
/// the board always shows the post-mutation truth (mirrors `ShopDetailBloc`).
class ProductsBoardBloc extends Bloc<ProductsBoardEvent, ProductsBoardState> {
  ProductsBoardBloc({
    required GetProducts getProducts,
    required SearchProducts searchProducts,
    required GetAllShops getAllShops,
    required SoftDeleteProduct softDeleteProduct,
    required RestoreProduct restoreProduct,
    required DuplicateProduct duplicateProduct,
    required HardDeleteProduct hardDeleteProduct,
    required BulkUpdateProducts bulkUpdateProducts,
  })  : _getProducts = getProducts,
        _searchProducts = searchProducts,
        _getAllShops = getAllShops,
        _softDeleteProduct = softDeleteProduct,
        _restoreProduct = restoreProduct,
        _duplicateProduct = duplicateProduct,
        _hardDeleteProduct = hardDeleteProduct,
        _bulkUpdateProducts = bulkUpdateProducts,
        super(const ProductsBoardState()) {
    on<ProductsBoardStarted>(_onStarted);
    on<ProductsBoardRetryRequested>((e, emit) => _load(emit));
    on<ProductsBoardFilterChanged>(_onFilterChanged);
    on<ProductsBoardLoadMoreRequested>(_onLoadMore);
    on<ProductsBoardSearchChanged>(_onSearchChanged);
    on<ProductSelectionToggled>(_onSelectionToggled);
    on<ProductsBoardSelectionCleared>(
      (e, emit) => emit(state.copyWith(selected: const {})),
    );
    on<ProductsBoardSoftDeleteRequested>(_onSoftDelete);
    on<ProductsBoardRestoreRequested>(_onRestore);
    on<ProductsBoardDuplicateRequested>(_onDuplicate);
    on<ProductsBoardHardDeleteRequested>(_onHardDelete);
    on<ProductsBoardBulkPriceRequested>(_onBulkPrice);
    on<ProductsBoardBulkStockRequested>(
      (e, emit) => _runBulk(emit, (p) => {'stockStatus': e.status.wire},
          'stockStatus=${e.status.wire}'),
    );
    on<ProductsBoardBulkPromoRequested>(
      (e, emit) =>
          _runBulk(emit, (p) => {'isPromo': e.value}, 'isPromo=${e.value}'),
    );
    on<ProductsBoardBulkFeaturedRequested>(
      (e, emit) => _runBulk(
          emit, (p) => {'isFeatured': e.value}, 'isFeatured=${e.value}'),
    );
    on<ProductsBoardBulkCategoryRequested>(
      (e, emit) => _runBulk(
        emit,
        (p) => {'category': e.category, 'subcategoryId': e.subcategoryId},
        'category=${e.category}/${e.subcategoryId}',
      ),
    );
  }

  final GetProducts _getProducts;
  final SearchProducts _searchProducts;
  final GetAllShops _getAllShops;
  final SoftDeleteProduct _softDeleteProduct;
  final RestoreProduct _restoreProduct;
  final DuplicateProduct _duplicateProduct;
  final HardDeleteProduct _hardDeleteProduct;
  final BulkUpdateProducts _bulkUpdateProducts;

  Future<void> _onStarted(ProductsBoardEvent event, Emitter<ProductsBoardState> emit) async {
    final shopsFuture = _getAllShops();
    await _load(emit);
    try {
      final shops = await shopsFuture;
      emit(state.copyWith(shops: shops));
    } catch (_) {
      // Shop dropdown staying empty degrades gracefully — the board itself
      // already loaded above.
    }
  }

  Future<void> _load(Emitter<ProductsBoardState> emit) async {
    emit(state.copyWith(status: ProductsBoardStatus.loading));
    try {
      final page = await _getProducts(
        shopId: state.shopId,
        category: state.category,
        subcategoryId: state.subcategoryId,
        stockStatus: state.stockStatus,
        isPromo: state.isPromo,
        deletedOnly: state.deletedOnly,
      );
      emit(state.copyWith(
        status: ProductsBoardStatus.loaded,
        products: page.products,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: ProductsBoardStatus.error));
    }
  }

  Future<void> _onFilterChanged(
    ProductsBoardFilterChanged event,
    Emitter<ProductsBoardState> emit,
  ) async {
    emit(state.copyWith(
      shopId: event.shopId,
      category: event.category,
      subcategoryId: event.subcategoryId,
      stockStatus: event.stockStatus,
      isPromo: event.isPromo,
      deletedOnly: event.deletedOnly,
      searchQuery: '',
      searchPool: null,
      selected: const {},
    ));
    await _load(emit);
  }

  Future<void> _onLoadMore(
    ProductsBoardLoadMoreRequested event,
    Emitter<ProductsBoardState> emit,
  ) async {
    if (state.status != ProductsBoardStatus.loaded ||
        state.loadingMore ||
        !state.hasMore ||
        state.products.isEmpty ||
        state.isSearching) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getProducts(
        shopId: state.shopId,
        category: state.category,
        subcategoryId: state.subcategoryId,
        stockStatus: state.stockStatus,
        isPromo: state.isPromo,
        deletedOnly: state.deletedOnly,
        cursor: state.products.last.id,
      );
      emit(state.copyWith(
        products: [...state.products, ...page.products],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }

  Future<void> _onSearchChanged(
    ProductsBoardSearchChanged event,
    Emitter<ProductsBoardState> emit,
  ) async {
    final query = event.query;
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchQuery: '', searchPool: null));
      return;
    }
    emit(state.copyWith(searchQuery: query));
    if (state.searchPool != null) return;
    emit(state.copyWith(searching: true));
    try {
      final pool = await _searchProducts(
        shopId: state.shopId,
        category: state.category,
        subcategoryId: state.subcategoryId,
        stockStatus: state.stockStatus,
        isPromo: state.isPromo,
        deletedOnly: state.deletedOnly,
      );
      emit(state.copyWith(searching: false, searchPool: pool));
    } catch (_) {
      emit(state.copyWith(searching: false));
    }
  }

  void _onSelectionToggled(
    ProductSelectionToggled event,
    Emitter<ProductsBoardState> emit,
  ) {
    final next = Set<String>.from(state.selected);
    if (!next.add(event.productId)) next.remove(event.productId);
    emit(state.copyWith(selected: next));
  }

  Future<void> _onSoftDelete(
    ProductsBoardSoftDeleteRequested event,
    Emitter<ProductsBoardState> emit,
  ) async {
    await _runSingle(emit, () => _softDeleteProduct(
          productId: event.productId,
          actorUid: event.actorUid,
        ));
  }

  Future<void> _onRestore(
    ProductsBoardRestoreRequested event,
    Emitter<ProductsBoardState> emit,
  ) =>
      _runSingle(emit, () => _restoreProduct(event.productId));

  Future<void> _onDuplicate(
    ProductsBoardDuplicateRequested event,
    Emitter<ProductsBoardState> emit,
  ) =>
      _runSingle(emit, () => _duplicateProduct(event.productId));

  Future<void> _onHardDelete(
    ProductsBoardHardDeleteRequested event,
    Emitter<ProductsBoardState> emit,
  ) =>
      _runSingle(emit, () => _hardDeleteProduct(event.productId));

  /// Runs one row-level mutation, then reloads the current (paginated or
  /// search-pool) view so the board reflects the real post-mutation state.
  Future<void> _runSingle(
    Emitter<ProductsBoardState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(bulkBusy: true, actionError: null));
    try {
      await action();
      emit(state.copyWith(bulkBusy: false));
      if (state.isSearching) {
        emit(state.copyWith(searchPool: null, searchQuery: ''));
      }
      await _load(emit);
    } catch (e) {
      emit(state.copyWith(bulkBusy: false, actionError: e.toString()));
    }
  }

  Future<void> _onBulkPrice(
    ProductsBoardBulkPriceRequested event,
    Emitter<ProductsBoardState> emit,
  ) async {
    final description = event.percentBps != null
        ? 'price ${event.percentBps! >= 0 ? '+' : ''}${event.percentBps! / 100}%'
        : 'price ${event.fixedDeltaMinor! >= 0 ? '+' : ''}${event.fixedDeltaMinor} piasters';
    await _runBulk(
      emit,
      (p) => {
        'priceMinor': _priceAfterBulkChange(
          p.priceMinor,
          percentBps: event.percentBps,
          fixedDeltaMinor: event.fixedDeltaMinor,
        ),
      },
      description,
    );
  }

  /// Round-half-up percent change (the M12 idiom: `(v*bps+5000)~/10000`,
  /// here `bps` is `10000 + percentBps` so it doubles as the multiplier), or
  /// a floored-at-zero fixed add.
  static int _priceAfterBulkChange(
    int priceMinor, {
    int? percentBps,
    int? fixedDeltaMinor,
  }) {
    if (percentBps != null) {
      final result = (priceMinor * (10000 + percentBps) + 5000) ~/ 10000;
      return result < 0 ? 0 : result;
    }
    final result = priceMinor + (fixedDeltaMinor ?? 0);
    return result < 0 ? 0 : result;
  }

  /// Builds a `{productId: fields}` map from the current selection using
  /// [fieldsFor] (which sees each selected product's own current data — bulk
  /// price needs the per-product `priceMinor` to round from), runs it as one
  /// chunked batch, then clears the selection and reloads.
  Future<void> _runBulk(
    Emitter<ProductsBoardState> emit,
    Map<String, dynamic> Function(Product product) fieldsFor,
    String changeDescription,
  ) async {
    final ids = state.selected.toList(growable: false);
    if (ids.isEmpty) return;
    final changes = <String, Map<String, dynamic>>{};
    for (final id in ids) {
      final product = state.productById(id);
      if (product != null) changes[id] = fieldsFor(product);
    }
    if (changes.isEmpty) return;

    emit(state.copyWith(bulkBusy: true, actionError: null));
    try {
      await _bulkUpdateProducts(changes: changes, changeDescription: changeDescription);
      emit(state.copyWith(bulkBusy: false, selected: const {}));
      if (state.isSearching) {
        emit(state.copyWith(searchPool: null, searchQuery: ''));
      }
      await _load(emit);
    } catch (e) {
      emit(state.copyWith(bulkBusy: false, actionError: e.toString()));
    }
  }
}
