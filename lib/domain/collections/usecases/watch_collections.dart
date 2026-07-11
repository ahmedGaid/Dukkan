import '../entities/shop_collection.dart';
import '../repositories/collections_repository.dart';

/// Realtime feed of one shop's collections (owner manager, customer filter
/// row). Thin pass-through.
class WatchCollections {
  const WatchCollections(this._repository);

  final CollectionsRepository _repository;

  Stream<List<ShopCollection>> call(String shopId) =>
      _repository.watchCollections(shopId);
}
