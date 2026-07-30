part of 'console_search_bloc.dart';

sealed class ConsoleSearchEvent extends Equatable {
  const ConsoleSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched by the dialog's `TextField` after its own 300ms debounce — the
/// bloc itself stays debounce-free so it's trivial to unit test.
class ConsoleSearchQueryChanged extends ConsoleSearchEvent {
  const ConsoleSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
