part of 'taxonomy_board_bloc.dart';

sealed class TaxonomyBoardEvent extends Equatable {
  const TaxonomyBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads every category (unfiltered, hidden
/// included; the board is small enough to need no pagination).
class TaxonomyBoardStarted extends TaxonomyBoardEvent {
  const TaxonomyBoardStarted();
}

class TaxonomyBoardRetryRequested extends TaxonomyBoardEvent {
  const TaxonomyBoardRetryRequested();
}

class TaxonomyBoardVisibilityToggled extends TaxonomyBoardEvent {
  const TaxonomyBoardVisibilityToggled(this.categoryId, this.value);

  final String categoryId;
  final bool value;

  @override
  List<Object?> get props => [categoryId, value];
}

/// An up/down tap — swaps the tapped category's `sort` with its neighbour's.
class TaxonomyBoardMoveRequested extends TaxonomyBoardEvent {
  const TaxonomyBoardMoveRequested(this.categoryId, {required this.up});

  final String categoryId;
  final bool up;

  @override
  List<Object?> get props => [categoryId, up];
}

class TaxonomyBoardCreateRequested extends TaxonomyBoardEvent {
  const TaxonomyBoardCreateRequested({
    required this.nameAr,
    required this.nameEn,
    this.iconName,
  });

  final String nameAr;
  final String nameEn;
  final String? iconName;

  @override
  List<Object?> get props => [nameAr, nameEn, iconName];
}

class TaxonomyBoardUpdateRequested extends TaxonomyBoardEvent {
  const TaxonomyBoardUpdateRequested({
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.iconName,
  });

  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String? iconName;

  @override
  List<Object?> get props => [categoryId, nameAr, nameEn, iconName];
}

class TaxonomyBoardDeleteRequested extends TaxonomyBoardEvent {
  const TaxonomyBoardDeleteRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
