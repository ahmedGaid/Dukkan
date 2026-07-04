import 'dart:async';

import 'package:dukkan/domain/shop/entities/shop.dart';
import 'package:dukkan/domain/shop/repositories/shop_repository.dart';
import 'package:dukkan/domain/shop/usecases/watch_shops.dart';
import 'package:dukkan/presentation/home/bloc/shops_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the shops stream by hand so the bloc can be tested without Firebase.
class _FakeShopRepository implements ShopRepository {
  final controller = StreamController<List<Shop>>();

  @override
  Stream<List<Shop>> watchShops() => controller.stream;

  @override
  Stream<Shop> watchShop(String shopId) => const Stream.empty();
}

Shop _shop(String id, List<String> categories) => Shop(
      id: id,
      ownerUid: 'owner-$id',
      name: 'Shop $id',
      nameAr: 'دكان $id',
      address: 'Cairo',
      isOpen: true,
      categories: categories,
    );

void main() {
  late _FakeShopRepository repo;
  late ShopsBloc bloc;

  setUp(() {
    repo = _FakeShopRepository();
    bloc = ShopsBloc(watchShops: WatchShops(repo));
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
  });

  test('loads shops and derives the category union in first-seen order',
      () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    repo.controller.add([
      _shop('a', ['خضروات', 'ألبان']),
      _shop('b', ['ألبان', 'مشروبات']),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.loaded);
    expect(bloc.state.categories, ['خضروات', 'ألبان', 'مشروبات']);
    expect(bloc.state.visibleShops.length, 2);
  });

  test('category filter narrows visibleShops, re-tap clears it', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([
      _shop('a', ['خضروات']),
      _shop('b', ['ألبان']),
    ]);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');
    expect(bloc.state.visibleShops.map((s) => s.id), ['a']);

    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleShops.length, 2);
  });

  test('drops a selected category that disappears from the feed', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);
    repo.controller.add([
      _shop('a', ['خضروات']),
    ]);
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');

    // Feed updates and that category is gone.
    repo.controller.add([
      _shop('b', ['ألبان']),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleShops.map((s) => s.id), ['b']);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    repo.controller.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.error);
  });
}
