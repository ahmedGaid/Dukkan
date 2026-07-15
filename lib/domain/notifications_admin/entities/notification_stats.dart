import 'package:equatable/equatable.dart';

/// All-time sent/failed counts for the history tab's header stat chips —
/// aggregate `count()` queries, never a document download (M13 lesson).
class NotificationStats extends Equatable {
  const NotificationStats({required this.sentCount, required this.failedCount});

  final int sentCount;
  final int failedCount;

  @override
  List<Object?> get props => [sentCount, failedCount];
}
