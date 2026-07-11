import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/finance/entities/finance_summary.dart';
import '../../../domain/finance/usecases/get_finance_summary.dart';

part 'finance_event.dart';
part 'finance_state.dart';

/// Drives the founder finance summary (M13): one load event (initial open
/// and pull-to-refresh both fire it), a single `getFinanceSummary()` await
/// covering all six metrics in one round trip pair (see
/// `FinanceRemoteDataSource`'s own internal `Future.wait`) — one
/// loading-to-loaded emit, no flicker.
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc({required GetFinanceSummary getFinanceSummary})
      : _getFinanceSummary = getFinanceSummary,
        super(const FinanceState()) {
    on<FinanceStarted>(_onLoad);
    on<FinanceRefreshRequested>(_onLoad);
  }

  final GetFinanceSummary _getFinanceSummary;

  Future<void> _onLoad(FinanceEvent event, Emitter<FinanceState> emit) async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final summary = await _getFinanceSummary();
      emit(state.copyWith(status: FinanceStatus.loaded, summary: summary));
    } catch (_) {
      emit(state.copyWith(status: FinanceStatus.error));
    }
  }
}
