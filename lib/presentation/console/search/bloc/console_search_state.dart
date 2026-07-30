part of 'console_search_bloc.dart';

enum ConsoleSearchStatus { idle, loading, ready }

class ConsoleSearchState extends Equatable {
  const ConsoleSearchState({
    this.status = ConsoleSearchStatus.idle,
    this.query = '',
    this.results = const ConsoleSearchResults(),
  });

  final ConsoleSearchStatus status;
  final String query;
  final ConsoleSearchResults results;

  ConsoleSearchState copyWith({
    ConsoleSearchStatus? status,
    String? query,
    ConsoleSearchResults? results,
  }) =>
      ConsoleSearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        results: results ?? this.results,
      );

  @override
  List<Object?> get props => [status, query, results];
}
