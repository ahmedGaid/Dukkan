part of 'devtools_bloc.dart';

sealed class DevToolsEvent extends Equatable {
  const DevToolsEvent();

  @override
  List<Object?> get props => [];
}

class DevToolsStarted extends DevToolsEvent {
  const DevToolsStarted();
}

class DevToolsHealthCheckRequested extends DevToolsEvent {
  const DevToolsHealthCheckRequested();
}

class DevToolsSeedRequested extends DevToolsEvent {
  const DevToolsSeedRequested({required this.rbac, required this.catalog, required this.customers});

  final bool rbac;
  final bool catalog;
  final bool customers;

  @override
  List<Object?> get props => [rbac, catalog, customers];
}

class DevToolsFakeCustomersRequested extends DevToolsEvent {
  const DevToolsFakeCustomersRequested(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class DevToolsShopSelected extends DevToolsEvent {
  const DevToolsShopSelected(this.shopId);

  final String shopId;

  @override
  List<Object?> get props => [shopId];
}

class DevToolsFakeOrdersRequested extends DevToolsEvent {
  const DevToolsFakeOrdersRequested(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class DevToolsFakeCleanupRequested extends DevToolsEvent {
  const DevToolsFakeCleanupRequested();
}

class DevToolsCachesClearRequested extends DevToolsEvent {
  const DevToolsCachesClearRequested();
}

class DevToolsTestNotificationRequested extends DevToolsEvent {
  const DevToolsTestNotificationRequested();
}

class DevToolsMigrationRunRequested extends DevToolsEvent {
  const DevToolsMigrationRunRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
