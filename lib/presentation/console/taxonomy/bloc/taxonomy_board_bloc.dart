import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/create_category.dart';
import '../../../../domain/admin/usecases/delete_category.dart';
import '../../../../domain/admin/usecases/get_all_categories.dart';
import '../../../../domain/admin/usecases/set_category_visible.dart';
import '../../../../domain/admin/usecases/swap_category_sort.dart';
import '../../../../domain/admin/usecases/update_category.dart';
import '../../../../domain/taxonomy/entities/category.dart';

part 'taxonomy_board_event.dart';
part 'taxonomy_board_state.dart';

/// Drives the console taxonomy board (`/console/taxonomy`, FC9). Every
/// mutation is Firestore-direct + best-effort audit (see
/// `AdminTaxonomyRepositoryImpl`); on success this reloads the whole tree so
/// the board always shows the post-mutation truth (mirrors `ShopDetailBloc`),
/// rather than guessing the new order/state client-side.
class TaxonomyBoardBloc extends Bloc<TaxonomyBoardEvent, TaxonomyBoardState> {
  TaxonomyBoardBloc({
    required GetAllCategories getAllCategories,
    required CreateCategory createCategory,
    required UpdateCategory updateCategory,
    required SetCategoryVisible setCategoryVisible,
    required SwapCategorySort swapCategorySort,
    required DeleteCategory deleteCategory,
  })  : _getAllCategories = getAllCategories,
        _createCategory = createCategory,
        _updateCategory = updateCategory,
        _setCategoryVisible = setCategoryVisible,
        _swapCategorySort = swapCategorySort,
        _deleteCategory = deleteCategory,
        super(const TaxonomyBoardState()) {
    on<TaxonomyBoardStarted>(_onLoad);
    on<TaxonomyBoardRetryRequested>(_onLoad);
    on<TaxonomyBoardVisibilityToggled>(
      (e, emit) => _runAction(
        emit,
        () => _setCategoryVisible(categoryId: e.categoryId, value: e.value),
      ),
    );
    on<TaxonomyBoardMoveRequested>(_onMove);
    on<TaxonomyBoardCreateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _createCategory(nameAr: e.nameAr, nameEn: e.nameEn, iconName: e.iconName),
      ),
    );
    on<TaxonomyBoardUpdateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _updateCategory(
          categoryId: e.categoryId,
          nameAr: e.nameAr,
          nameEn: e.nameEn,
          iconName: e.iconName,
        ),
      ),
    );
    on<TaxonomyBoardDeleteRequested>(
      (e, emit) => _runAction(emit, () => _deleteCategory(e.categoryId)),
    );
  }

  final GetAllCategories _getAllCategories;
  final CreateCategory _createCategory;
  final UpdateCategory _updateCategory;
  final SetCategoryVisible _setCategoryVisible;
  final SwapCategorySort _swapCategorySort;
  final DeleteCategory _deleteCategory;

  Future<void> _onLoad(
    TaxonomyBoardEvent event,
    Emitter<TaxonomyBoardState> emit,
  ) async {
    emit(state.copyWith(status: TaxonomyBoardStatus.loading));
    try {
      final categories = await _getAllCategories();
      emit(state.copyWith(status: TaxonomyBoardStatus.loaded, categories: categories));
    } catch (_) {
      emit(state.copyWith(status: TaxonomyBoardStatus.error));
    }
  }

  Future<void> _onMove(
    TaxonomyBoardMoveRequested event,
    Emitter<TaxonomyBoardState> emit,
  ) async {
    final categories = state.categories;
    final index = categories.indexWhere((c) => c.id == event.categoryId);
    if (index == -1) return;
    final neighborIndex = event.up ? index - 1 : index + 1;
    if (neighborIndex < 0 || neighborIndex >= categories.length) return;
    final a = categories[index];
    final b = categories[neighborIndex];
    await _runAction(
      emit,
      () => _swapCategorySort(aId: a.id, aSort: b.sort, bId: b.id, bSort: a.sort),
    );
  }

  /// Runs one Firestore-direct mutation; on success reloads the whole tree
  /// so the board reflects the real post-mutation state. On failure,
  /// surfaces [TaxonomyBoardState.actionError] for a snackbar and keeps the
  /// last-known-good list.
  Future<void> _runAction(
    Emitter<TaxonomyBoardState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: false));
    try {
      await action();
      final categories = await _getAllCategories();
      emit(state.copyWith(
        status: TaxonomyBoardStatus.loaded,
        actionBusy: false,
        categories: categories,
      ));
    } catch (_) {
      emit(state.copyWith(actionBusy: false, actionError: true));
    }
  }
}
