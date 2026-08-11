import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/data/order/repositories/order_repository_impl.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('online: updateOrderStatus calls the remote directly, never the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = true;
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => remoteCalls++,
      networkInfo: network,
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.accepted);

    expect(remoteCalls, 1);
    expect(queue.pendingForOrder('o1'), isEmpty);
    addTearDown(queue.dispose);
  });

  test('offline: updateOrderStatus enqueues instead of calling the remote', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = false;
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => remoteCalls++,
      networkInfo: network,
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.rejected);

    expect(remoteCalls, 0);
    expect(queue.pendingForOrder('o1').single.targetStatus, OrderStatus.rejected);
    expect(queue.pendingForOrder('o1').single.actorUid, 'u1');
    addTearDown(queue.dispose);
  });
}
