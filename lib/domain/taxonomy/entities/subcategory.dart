import 'package:equatable/equatable.dart';

/// One leaf under a [Category] — e.g. فواكه under خضروات وفواكه. Seed-managed,
/// never created by an owner.
class Subcategory extends Equatable {
  const Subcategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  @override
  List<Object?> get props => [id, nameAr, nameEn];
}
