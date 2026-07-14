import '../repositories/admin_taxonomy_repository.dart';

/// The board's up/down reorder tap — swaps two adjacent categories' `sort`.
/// Thin pass-through.
class SwapCategorySort {
  const SwapCategorySort(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<void> call({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) =>
      _repository.swapSort(aId: aId, aSort: aSort, bId: bId, bSort: bSort);
}
