import 'package:dukkan/domain/product/entities/product.dart';
import 'package:dukkan/domain/product/entities/stock_status.dart';
import 'package:dukkan/presentation/cart/bloc/cart_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(String id, {required String shopId, int priceMinor = 1000}) =>
    Product(
      id: id,
      shopId: shopId,
      name: 'Item $id',
      nameAr: 'منتج $id',
      priceMinor: priceMinor,
      category: 'عام',
      stockStatus: StockStatus.inStock,
      isPromo: false,
    );

void main() {
  late CartBloc bloc;

  setUp(() => bloc = CartBloc());
  tearDown(() => bloc.close());

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('adding a product starts the cart with that shop', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();

    expect(bloc.state.shopId, 's1');
    expect(bloc.state.quantityOf('a'), 1);
    expect(bloc.state.itemCount, 1);
  });

  test('adding the same product twice sums the quantity, not a new line', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1'), quantity: 2));
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();

    expect(bloc.state.itemCount, 1);
    expect(bloc.state.quantityOf('a'), 3);
  });

  test('itemCount is distinct products, never summed quantities', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1'), quantity: 5));
    bloc.add(CartItemAdded(product: _product('b', shopId: 's1'), quantity: 1));
    await tick();

    expect(bloc.state.itemCount, 2);
  });

  test('totalMinor sums each line\'s price × quantity', () async {
    bloc.add(CartItemAdded(
      product: _product('a', shopId: 's1', priceMinor: 1000),
      quantity: 2,
    ));
    bloc.add(CartItemAdded(
      product: _product('b', shopId: 's1', priceMinor: 500),
      quantity: 3,
    ));
    await tick();

    expect(bloc.state.totalMinor, 1000 * 2 + 500 * 3);
  });

  test('adding a product from a different shop replaces the cart', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();
    bloc.add(CartItemAdded(product: _product('b', shopId: 's2')));
    await tick();

    expect(bloc.state.shopId, 's2');
    expect(bloc.state.quantityOf('a'), 0);
    expect(bloc.state.quantityOf('b'), 1);
    expect(bloc.state.itemCount, 1);
  });

  test('incrementing raises quantity by one', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();
    bloc.add(const CartItemIncremented('a'));
    await tick();

    expect(bloc.state.quantityOf('a'), 2);
  });

  test('decrementing above 1 lowers quantity by one', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1'), quantity: 2));
    await tick();
    bloc.add(const CartItemDecremented('a'));
    await tick();

    expect(bloc.state.quantityOf('a'), 1);
  });

  test('decrementing at 1 removes the line', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();
    bloc.add(const CartItemDecremented('a'));
    await tick();

    expect(bloc.state.quantityOf('a'), 0);
    expect(bloc.state.itemCount, 0);
  });

  test('removing the last item clears the shop id too', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1')));
    await tick();
    bloc.add(const CartItemRemoved('a'));
    await tick();

    expect(bloc.state.isEmpty, isTrue);
    expect(bloc.state.shopId, isNull);
  });

  test('clearing empties the cart and drops the shop id', () async {
    bloc.add(CartItemAdded(product: _product('a', shopId: 's1'), quantity: 4));
    await tick();
    bloc.add(const CartCleared());
    await tick();

    expect(bloc.state.isEmpty, isTrue);
    expect(bloc.state.shopId, isNull);
  });
}
