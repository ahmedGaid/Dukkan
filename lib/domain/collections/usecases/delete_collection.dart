import '../repositories/collections_repository.dart';

/// Removes a collection doc. Products keep their (now stale) `collectionIds`
/// entry — ignored at render time, no fan-out delete.
class DeleteCollection {
  const DeleteCollection(this._repository);

  final CollectionsRepository _repository;

  Future<void> call(String shopId, String collectionId) =>
      _repository.deleteCollection(shopId, collectionId);
}
