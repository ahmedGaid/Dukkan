import 'package:equatable/equatable.dart';

import 'order_status.dart';

/// One row of the order timeline. Appended on create and on every
/// transition — never edited, never removed.
class StatusChange extends Equatable {
  const StatusChange({
    required this.status,
    required this.at,
    required this.byUid,
    this.forced = false,
  });

  final OrderStatus status;
  final DateTime at;
  final String byUid;

  /// True for a Founder Console correction (FC10 force-status/cancel) rather
  /// than a normal customer/owner/courier transition — the timeline shows a
  /// «تصحيح إداري» chip on these rows.
  final bool forced;

  @override
  List<Object?> get props => [status, at, byUid, forced];
}
