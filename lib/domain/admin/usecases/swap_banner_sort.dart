import '../repositories/admin_promos_repository.dart';

class SwapBannerSort {
  const SwapBannerSort(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) =>
      _repository.swapBannerSort(aId: aId, aSort: aSort, bId: bId, bSort: bSort);
}
