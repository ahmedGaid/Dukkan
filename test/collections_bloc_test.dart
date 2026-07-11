import 'dart:async';

import 'package:dukkan/domain/collections/entities/shop_collection.dart';
import 'package:dukkan/domain/collections/repositories/collections_repository.dart';
import 'package:dukkan/domain/collections/usecases/create_collection.dart';
import 'package:dukkan/domain/collections/usecases/delete_collection.dart';
import 'package:dukkan/domain/collections/usecases/rename_collection.dart';
import 'package:dukkan/domain/collections/usecases/watch_collections.dart';
import 'package:dukkan/presentation/catalog/bloc/collections_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the collections stream by hand and can be told to fail the next
/// mutation call (mirrors `_FakeOrderRepository` in owner_orders_bloc_test.dart).
class _FakeCollectionsRepository implements CollectionsRepository {
  final controller = StreamController<List<ShopCollection>>.broadcast();
  bool failMutations = false;

  final createCalls = <(String, String, int)>[];

  @override
  Stream<List<ShopCollection>> watchCollections(String shopId) =>
      controller.stream;

  @override
  Future<List<ShopCollection>> getCollections(String shopId) =>
      throw UnimplementedError();

  @override
  Future<ShopCollection> createCollection(
    String shopId, {
    required String nameAr,
    required String nameEn,
    required int sort,
  }) async {
    createCalls.add((nameAr, nameEn, sort));
    if (failMutations) throw Exception('boom');
    return ShopCollection(id: 'new', nameAr: nameAr, nameEn: nameEn, sort: sort);
  }

  @override
  Future<void> renameCollection(
    String shopId,
    String collectionId, {
    required String nameAr,
    required String nameEn,
  }) async {
    if (failMutations) throw Exception('boom');
  }

  @override
  Future<void> deleteCollection(String shopId, String collectionId) async {
    if (failMutations) throw Exception('boom');
  }
}

ShopCollection _collection(String id) =>
    ShopCollection(id: id, nameAr: 'مجموعة $id', nameEn: 'Collection $id', sort: 0);

void main() {
  late _FakeCollectionsRepository repo;
  late CollectionsBloc bloc;

  setUp(() {
    repo = _FakeCollectionsRepository();
    bloc = CollectionsBloc(
      shopId: 's',
      watchCollections: WatchCollections(repo),
      createCollection: CreateCollection(repo),
      renameCollection: RenameCollection(repo),
      deleteCollection: DeleteCollection(repo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('loads collections from the shop stream', () async {
    bloc.add(const CollectionsStarted());
    await tick();

    repo.controller.add([_collection('a')]);
    await tick();

    expect(bloc.state.status, CollectionsStatus.loaded);
    expect(bloc.state.collections.single.id, 'a');
  });

  test('an empty feed still reaches loaded (not stuck loading)', () async {
    bloc.add(const CollectionsStarted());
    await tick();

    repo.controller.add(const []);
    await tick();

    expect(bloc.state.status, CollectionsStatus.loaded);
    expect(bloc.state.collections, isEmpty);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const CollectionsStarted());
    await tick();

    repo.controller.addError(Exception('boom'));
    await tick();

    expect(bloc.state.status, CollectionsStatus.error);
  });

  test('retry re-subscribes after an error', () async {
    bloc.add(const CollectionsStarted());
    await tick();
    repo.controller.addError(Exception('boom'));
    await tick();
    expect(bloc.state.status, CollectionsStatus.error);

    bloc.add(const CollectionsRetryRequested());
    await tick();
    repo.controller.add([_collection('a')]);
    await tick();

    expect(bloc.state.status, CollectionsStatus.loaded);
    expect(bloc.state.collections.single.id, 'a');
  });

  test('create passes the next sort index (current list length)', () async {
    bloc.add(const CollectionsStarted());
    await tick();
    repo.controller.add([_collection('a'), _collection('b')]);
    await tick();

    bloc.add(const CollectionsCreateRequested(nameAr: 'عروض', nameEn: 'Offers'));
    await tick();

    expect(repo.createCalls.single, ('عروض', 'Offers', 2));
    expect(bloc.state.actionStatus, isNot(CollectionsActionStatus.failure));
  });

  test('a failed create surfaces once as an action failure', () async {
    repo.failMutations = true;
    bloc.add(const CollectionsStarted());
    await tick();
    repo.controller.add(const []);
    await tick();

    bloc.add(const CollectionsCreateRequested(nameAr: 'عروض', nameEn: 'Offers'));
    await tick();

    expect(bloc.state.actionStatus, CollectionsActionStatus.failure);
  });

  test('a failed rename surfaces as an action failure', () async {
    repo.failMutations = true;
    bloc.add(const CollectionsStarted());
    await tick();
    repo.controller.add([_collection('a')]);
    await tick();

    bloc.add(const CollectionsRenameRequested(
      collectionId: 'a',
      nameAr: 'جديد',
      nameEn: 'New',
    ));
    await tick();

    expect(bloc.state.actionStatus, CollectionsActionStatus.failure);
  });

  test('a failed delete surfaces as an action failure', () async {
    repo.failMutations = true;
    bloc.add(const CollectionsStarted());
    await tick();
    repo.controller.add([_collection('a')]);
    await tick();

    bloc.add(const CollectionsDeleteRequested('a'));
    await tick();

    expect(bloc.state.actionStatus, CollectionsActionStatus.failure);
  });
}
