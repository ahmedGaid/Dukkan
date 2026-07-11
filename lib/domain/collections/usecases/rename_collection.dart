import '../repositories/collections_repository.dart';

/// Overwrites a collection's bilingual name. Thin pass-through.
class RenameCollection {
  const RenameCollection(this._repository);

  final CollectionsRepository _repository;

  Future<void> call(
    String shopId,
    String collectionId, {
    required String nameAr,
    required String nameEn,
  }) {
    return _repository.renameCollection(
      shopId,
      collectionId,
      nameAr: nameAr,
      nameEn: nameEn,
    );
  }
}
