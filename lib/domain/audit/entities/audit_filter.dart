import 'package:equatable/equatable.dart';

/// The set of narrowing conditions for an audit-log query. Every field is
/// optional; an all-null filter ([isEmpty]) returns the whole trail, newest
/// first. Each non-null equality field becomes a Firestore `where`, and
/// [from]/[to] bound `createdAt` (see `AuditRemoteDataSource`).
///
/// Filter combinations are covered by the single-dimension composite indexes
/// shipped in `firestore.indexes.json` (one equality field + the `createdAt`
/// order/range). Stacking several equality fields at once is an intentional
/// edge — Firestore surfaces the exact extra index it needs if it is ever hit.
class AuditFilter extends Equatable {
  const AuditFilter({
    this.action,
    this.targetType,
    this.actorUid,
    this.targetId,
    this.from,
    this.to,
  });

  final String? action;
  final String? targetType;
  final String? actorUid;
  final String? targetId;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      action == null &&
      targetType == null &&
      actorUid == null &&
      targetId == null &&
      from == null &&
      to == null;

  /// Sentinel so a caller can clear a field back to null (a plain nullable
  /// parameter can't tell "leave unchanged" from "set to null").
  static const _unset = Object();

  AuditFilter copyWith({
    Object? action = _unset,
    Object? targetType = _unset,
    Object? actorUid = _unset,
    Object? targetId = _unset,
    Object? from = _unset,
    Object? to = _unset,
  }) {
    return AuditFilter(
      action: action == _unset ? this.action : action as String?,
      targetType:
          targetType == _unset ? this.targetType : targetType as String?,
      actorUid: actorUid == _unset ? this.actorUid : actorUid as String?,
      targetId: targetId == _unset ? this.targetId : targetId as String?,
      from: from == _unset ? this.from : from as DateTime?,
      to: to == _unset ? this.to : to as DateTime?,
    );
  }

  @override
  List<Object?> get props => [action, targetType, actorUid, targetId, from, to];
}
