import 'package:equatable/equatable.dart';

import 'order_status.dart';

/// One row of the order timeline. Appended on create and on every
/// transition — never edited, never removed.
class StatusChange extends Equatable {
  const StatusChange({
    required this.status,
    required this.at,
    required this.byUid,
  });

  final OrderStatus status;
  final DateTime at;
  final String byUid;

  @override
  List<Object?> get props => [status, at, byUid];
}
