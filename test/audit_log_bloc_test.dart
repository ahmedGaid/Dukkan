import 'package:dukkan/domain/audit/entities/audit_entry.dart';
import 'package:dukkan/domain/audit/entities/audit_filter.dart';
import 'package:dukkan/domain/audit/entities/audit_page.dart';
import 'package:dukkan/domain/audit/repositories/audit_repository.dart';
import 'package:dukkan/domain/audit/usecases/get_audit_entries.dart';
import 'package:dukkan/presentation/console/audit/bloc/audit_log_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the filter + cursor it was called with, and returns a queued page
/// (the first-page result when no cursor, the second-page result otherwise) —
/// enough to prove the BLoC maps events to the right query.
class _FakeAuditRepository implements AuditRepository {
  AuditFilter? lastFilter;
  String? lastAfter;
  int calls = 0;
  bool shouldFail = false;

  AuditPage firstPage = const AuditPage(entries: [], hasMore: false);
  AuditPage secondPage = const AuditPage(entries: [], hasMore: false);

  @override
  Future<AuditPage> getEntries({
    required AuditFilter filter,
    String? afterCreatedAt,
  }) async {
    calls++;
    lastFilter = filter;
    lastAfter = afterCreatedAt;
    if (shouldFail) throw Exception('boom');
    return afterCreatedAt == null ? firstPage : secondPage;
  }
}

AuditEntry _entry(String id, DateTime at) => AuditEntry(
      id: id,
      actorUid: 'actor-$id',
      action: 'order.forceStatus',
      targetType: 'order',
      targetId: 'o-$id',
      createdAt: at,
    );

void main() {
  late _FakeAuditRepository repo;
  late AuditLogBloc bloc;

  final t1 = DateTime.utc(2026, 7, 13, 10).toLocal();
  final t2 = DateTime.utc(2026, 7, 13, 9).toLocal();
  final t3 = DateTime.utc(2026, 7, 13, 8).toLocal();

  setUp(() {
    repo = _FakeAuditRepository()
      ..firstPage = AuditPage(entries: [_entry('1', t1), _entry('2', t2)], hasMore: true)
      ..secondPage = AuditPage(entries: [_entry('3', t3)], hasMore: false);
    bloc = AuditLogBloc(getAuditEntries: GetAuditEntries(repo));
  });

  tearDown(() => bloc.close());

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('start loads the first page (no cursor) and reaches loaded', () async {
    bloc.add(const AuditStarted());
    await settle();

    expect(bloc.state.status, AuditLogStatus.loaded);
    expect(bloc.state.entries.map((e) => e.id), ['1', '2']);
    expect(bloc.state.hasMore, isTrue);
    expect(repo.lastAfter, isNull);
  });

  test('a filter change reloads from the top with the new filter', () async {
    bloc.add(const AuditStarted());
    await settle();

    const filter = AuditFilter(action: 'user.disable', targetType: 'user');
    bloc.add(const AuditFilterChanged(filter));
    await settle();

    expect(bloc.state.filter, filter);
    expect(repo.lastFilter, filter);
    expect(repo.lastAfter, isNull); // fresh load, not paginated
    expect(bloc.state.entries.map((e) => e.id), ['1', '2']);
  });

  test('load more appends the next page using the last entry as cursor',
      () async {
    bloc.add(const AuditStarted());
    await settle();

    bloc.add(const AuditLoadMoreRequested());
    await settle();

    expect(bloc.state.entries.map((e) => e.id), ['1', '2', '3']);
    expect(bloc.state.hasMore, isFalse);
    expect(repo.lastAfter, t2.toUtc().toIso8601String());
  });

  test('load more is ignored once there is no more to load', () async {
    repo.firstPage = AuditPage(entries: [_entry('1', t1)], hasMore: false);
    bloc.add(const AuditStarted());
    await settle();
    final callsAfterLoad = repo.calls;

    bloc.add(const AuditLoadMoreRequested());
    await settle();

    expect(repo.calls, callsAfterLoad); // no extra fetch
  });

  test('a failed load surfaces as error status', () async {
    repo.shouldFail = true;
    bloc.add(const AuditStarted());
    await settle();

    expect(bloc.state.status, AuditLogStatus.error);
  });
}
