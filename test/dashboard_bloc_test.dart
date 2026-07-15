import 'package:dukkan/domain/audit/entities/audit_entry.dart';
import 'package:dukkan/domain/audit/entities/audit_filter.dart';
import 'package:dukkan/domain/audit/entities/audit_page.dart';
import 'package:dukkan/domain/audit/repositories/audit_repository.dart';
import 'package:dukkan/domain/audit/usecases/get_audit_entries.dart';
import 'package:dukkan/domain/dashboard/entities/daily_order_count.dart';
import 'package:dukkan/domain/dashboard/entities/dashboard_summary.dart';
import 'package:dukkan/domain/dashboard/repositories/dashboard_repository.dart';
import 'package:dukkan/domain/dashboard/usecases/get_dashboard_summary.dart';
import 'package:dukkan/presentation/console/dashboard/bloc/dashboard_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  DashboardSummary? next;
  bool shouldFail = false;
  bool? lastIncludeUsers;
  int calls = 0;

  @override
  Future<DashboardSummary> getSummary({required bool includeUsers}) async {
    calls++;
    lastIncludeUsers = includeUsers;
    if (shouldFail) throw Exception('boom');
    return next!;
  }
}

class _FakeAuditRepository implements AuditRepository {
  AuditPage page = const AuditPage(entries: [], hasMore: false);
  int calls = 0;

  @override
  Future<AuditPage> getEntries({
    required AuditFilter filter,
    String? afterCreatedAt,
  }) async {
    calls++;
    return page;
  }
}

AuditEntry _entry(String id) => AuditEntry(
      id: id,
      actorUid: 'actor',
      action: 'order.forceStatus',
      targetType: 'order',
      targetId: 'o-$id',
      createdAt: DateTime(2026, 7, 13, 10),
    );

DashboardSummary _summary() => DashboardSummary(
      ordersToday: 3,
      revenueTodayMinor: 5000,
      commissionTodayMinor: 500,
      ordersWaiting: 1,
      totalUsers: 42,
      totalShops: 7,
      totalProducts: 100,
      driversOnline: 2,
      pendingShops: 0,
      last7Days: [
        for (var i = 0; i < 7; i++)
          DailyOrderCount(day: DateTime(2026, 7, 7 + i), count: i),
      ],
      failedNotifications7d: 0,
    );

void main() {
  late _FakeDashboardRepository dashRepo;
  late _FakeAuditRepository auditRepo;
  late DashboardBloc bloc;

  setUp(() {
    dashRepo = _FakeDashboardRepository()..next = _summary();
    auditRepo = _FakeAuditRepository()
      ..page = AuditPage(entries: [_entry('1'), _entry('2')], hasMore: false);
    bloc = DashboardBloc(
      getDashboardSummary: GetDashboardSummary(dashRepo),
      getAuditEntries: GetAuditEntries(auditRepo),
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('start loads summary + activity, passing the viewer permissions', () async {
    final states = <DashboardState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const DashboardStarted(canReadUsers: true, canReadAudit: true));
    await settle();
    await sub.cancel();

    expect(states.first.status, DashboardStatus.loading);
    expect(states.last.status, DashboardStatus.loaded);
    expect(states.last.summary!.ordersToday, 3);
    expect(states.last.recentActivity!.map((e) => e.id), ['1', '2']);
    expect(dashRepo.lastIncludeUsers, isTrue);
    expect(auditRepo.calls, 1);
  });

  test('without users.read the summary skips the users count', () async {
    bloc.add(const DashboardStarted(canReadUsers: false, canReadAudit: true));
    await settle();

    expect(dashRepo.lastIncludeUsers, isFalse);
  });

  test('without auditlogs.read the activity strip is null and unqueried',
      () async {
    bloc.add(const DashboardStarted(canReadUsers: true, canReadAudit: false));
    await settle();

    expect(bloc.state.status, DashboardStatus.loaded);
    expect(bloc.state.recentActivity, isNull);
    expect(bloc.state.canViewAudit, isFalse);
    expect(auditRepo.calls, 0);
  });

  test('recent activity is capped at 10 entries', () async {
    auditRepo.page = AuditPage(
      entries: [for (var i = 0; i < 15; i++) _entry('$i')],
      hasMore: true,
    );

    bloc.add(const DashboardStarted(canReadUsers: true, canReadAudit: true));
    await settle();

    expect(bloc.state.recentActivity!.length, 10);
  });

  test('a failed load surfaces as error status', () async {
    dashRepo.shouldFail = true;
    bloc.add(const DashboardStarted(canReadUsers: true, canReadAudit: true));
    await settle();

    expect(bloc.state.status, DashboardStatus.error);
  });

  test('refresh recovers from a prior error', () async {
    dashRepo.shouldFail = true;
    bloc.add(const DashboardStarted(canReadUsers: true, canReadAudit: true));
    await settle();
    expect(bloc.state.status, DashboardStatus.error);

    dashRepo.shouldFail = false;
    bloc.add(const DashboardRefreshRequested());
    await settle();

    expect(bloc.state.status, DashboardStatus.loaded);
  });
}
