import 'package:dukkan/domain/finance/entities/finance_summary.dart';
import 'package:dukkan/domain/finance/repositories/finance_repository.dart';
import 'package:dukkan/domain/finance/usecases/get_finance_summary.dart';
import 'package:dukkan/presentation/finance/bloc/finance_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Future-based fake (no stream) — mirrors `_FakeCollectionsRepository`'s
/// `failMutations` toggle, but for a one-shot read instead of a stream.
class _FakeFinanceRepository implements FinanceRepository {
  FinanceSummary? nextSummary;
  bool shouldFail = false;
  int calls = 0;

  @override
  Future<FinanceSummary> getSummary() async {
    calls++;
    if (shouldFail) throw Exception('boom');
    return nextSummary!;
  }
}

const _summary = FinanceSummary(
  totalOrders: 10,
  deliveredOrders: 6,
  cancelledOrders: 2,
  commissionMinor: 500,
  deliveryRevenueMinor: 100,
);

void main() {
  late _FakeFinanceRepository repo;
  late FinanceBloc bloc;

  setUp(() {
    repo = _FakeFinanceRepository()..nextSummary = _summary;
    bloc = FinanceBloc(getFinanceSummary: GetFinanceSummary(repo));
  });

  tearDown(() => bloc.close());

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('starts loading then reaches loaded with the summary', () async {
    final states = <FinanceState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const FinanceStarted());
    await tick();
    await sub.cancel();

    expect(states.first.status, FinanceStatus.loading);
    expect(states.last.status, FinanceStatus.loaded);
    expect(states.last.summary!.totalOrders, 10);
  });

  test('a failed load surfaces as error status', () async {
    repo.shouldFail = true;
    bloc.add(const FinanceStarted());
    await tick();

    expect(bloc.state.status, FinanceStatus.error);
  });

  test('refresh re-runs the same load and can recover from a prior error', () async {
    repo.shouldFail = true;
    bloc.add(const FinanceStarted());
    await tick();
    expect(bloc.state.status, FinanceStatus.error);

    repo.shouldFail = false;
    bloc.add(const FinanceRefreshRequested());
    await tick();

    expect(bloc.state.status, FinanceStatus.loaded);
    expect(repo.calls, 2);
  });
}
