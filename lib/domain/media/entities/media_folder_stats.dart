import 'package:equatable/equatable.dart';

/// Object count + byte total for one folder — one row of `MediaStats.byFolder`.
class MediaFolderStats extends Equatable {
  const MediaFolderStats({required this.count, required this.bytes});

  final int count;
  final int bytes;

  @override
  List<Object?> get props => [count, bytes];
}
