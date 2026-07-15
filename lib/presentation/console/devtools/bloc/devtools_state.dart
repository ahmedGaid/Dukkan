part of 'devtools_bloc.dart';

enum DevToolsPageStatus { loading, loaded, error }

class DevToolsState extends Equatable {
  const DevToolsState({
    this.status = DevToolsPageStatus.loading,
    this.shops = const [],
    this.selectedShopId,
    this.migrations = const [],
    this.healthResults = const [],
    this.busyTools = const {},
    this.fakeCustomersCreated,
    this.fakeOrdersCreated,
    this.fakeCleanupCount,
    this.cachesCleared = false,
    this.notifySent,
    this.seedOk,
    this.errorTool,
    this.errorMessage,
  });

  final DevToolsPageStatus status;
  final List<Shop> shops;
  final String? selectedShopId;
  final List<MigrationStatus> migrations;
  final List<HealthCheckResult> healthResults;

  /// Tool ids currently running (`'health'`, `'seed'`, `'fakeCustomers'`,
  /// `'fakeOrders'`, `'fakeCleanup'`, `'caches'`, `'notify'`, or a migration
  /// id) — one set covers every tool's busy state instead of a field each.
  final Set<String> busyTools;

  final int? fakeCustomersCreated;
  final int? fakeOrdersCreated;
  final int? fakeCleanupCount;
  final bool cachesCleared;
  final bool? notifySent;
  final bool? seedOk;

  /// The last failure, if any — `errorTool` names which tool, so the UI can
  /// show it inline rather than a generic toast.
  final String? errorTool;
  final String? errorMessage;

  bool isBusy(String tool) => busyTools.contains(tool);

  DevToolsState copyWith({
    DevToolsPageStatus? status,
    List<Shop>? shops,
    String? selectedShopId,
    List<MigrationStatus>? migrations,
    List<HealthCheckResult>? healthResults,
    Set<String>? busyTools,
    int? fakeCustomersCreated,
    int? fakeOrdersCreated,
    int? fakeCleanupCount,
    bool? cachesCleared,
    bool? notifySent,
    bool? seedOk,
    String? errorTool,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DevToolsState(
      status: status ?? this.status,
      shops: shops ?? this.shops,
      selectedShopId: selectedShopId ?? this.selectedShopId,
      migrations: migrations ?? this.migrations,
      healthResults: healthResults ?? this.healthResults,
      busyTools: busyTools ?? this.busyTools,
      fakeCustomersCreated: fakeCustomersCreated ?? this.fakeCustomersCreated,
      fakeOrdersCreated: fakeOrdersCreated ?? this.fakeOrdersCreated,
      fakeCleanupCount: fakeCleanupCount ?? this.fakeCleanupCount,
      cachesCleared: cachesCleared ?? this.cachesCleared,
      notifySent: notifySent ?? this.notifySent,
      seedOk: seedOk ?? this.seedOk,
      errorTool: clearError ? null : (errorTool ?? this.errorTool),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        shops,
        selectedShopId,
        migrations,
        healthResults,
        busyTools,
        fakeCustomersCreated,
        fakeOrdersCreated,
        fakeCleanupCount,
        cachesCleared,
        notifySent,
        seedOk,
        errorTool,
        errorMessage,
      ];
}
