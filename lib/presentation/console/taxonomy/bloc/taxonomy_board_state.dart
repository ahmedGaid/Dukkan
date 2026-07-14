part of 'taxonomy_board_bloc.dart';

enum TaxonomyBoardStatus { loading, loaded, error }

class TaxonomyBoardState extends Equatable {
  const TaxonomyBoardState({
    this.status = TaxonomyBoardStatus.loading,
    this.categories = const [],
    this.actionBusy = false,
    this.actionError = false,
  });

  final TaxonomyBoardStatus status;

  /// Sorted by `sort` ascending, hidden categories included.
  final List<Category> categories;

  final bool actionBusy;

  /// One-shot flag for the page's snackbar listener — the bloc resets it to
  /// false on every successful reload, so it never re-fires on rebuild.
  final bool actionError;

  TaxonomyBoardState copyWith({
    TaxonomyBoardStatus? status,
    List<Category>? categories,
    bool? actionBusy,
    bool? actionError,
  }) {
    return TaxonomyBoardState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [status, categories, actionBusy, actionError];
}
