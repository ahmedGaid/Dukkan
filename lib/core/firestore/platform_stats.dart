/// Denormalized platform counters that keep the Founder Console dashboard
/// (FC5) offline-capable (Phase 8 O1). Firestore's `count()`/`sum()`
/// aggregates can NEVER be served from local cache — a hard SDK
/// restriction, not a bug — so the dashboard bumps these plain fields
/// alongside every real mutation instead, the same pattern already used for
/// `/shops.ratingSum` and `/drivers.activeOrdersCount`. A plain doc read
/// *can* be served offline, so the dashboard stays usable without a
/// connection once these have been read at least once.
///
/// `/stats/global` — platform-wide, not day-scoped: totalShops,
/// totalProducts, totalUsers (monotonic — never decrease, since none of
/// those docs are ever hard-deleted by the app) and pendingShops,
/// driversOnline, ordersWaiting (bidirectional — track a live in-progress
/// count).
///
/// `/stats/daily-{yyyy-MM-dd}` — one doc per calendar day, keyed by the
/// mutated order's `createdAt` day (so "today" tiles and the 7-day chart
/// read the exact same bucket a delivered-today order landed in when it was
/// first placed, matching the original aggregate's semantics): ordersCount,
/// deliveredCount, revenueMinor, commissionMinor, failedNotifications.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

String dailyStatsDocId(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return 'daily-$y-$m-$d';
}

DocumentReference<Map<String, dynamic>> globalStatsRef(FirebaseFirestore db) =>
    db.collection('stats').doc('global');

DocumentReference<Map<String, dynamic>> dailyStatsRef(
  FirebaseFirestore db,
  DateTime day,
) =>
    db.collection('stats').doc(dailyStatsDocId(day));

/// Bumps one or more `/stats/global` fields by the given deltas (positive or
/// negative). Pass [txn] to fold this into a transaction that's already
/// reading/writing other docs (same call, atomic); omitted, it fires as its
/// own best-effort write — acceptable here since these are display counters,
/// never a gate on the mutation they ride alongside.
void bumpGlobalStats(
  FirebaseFirestore db,
  Map<String, int> deltas, {
  Transaction? txn,
}) {
  if (deltas.isEmpty) return;
  final ref = globalStatsRef(db);
  final data = {
    for (final e in deltas.entries) e.key: FieldValue.increment(e.value),
  };
  if (txn != null) {
    txn.set(ref, data, SetOptions(merge: true));
  } else {
    unawaited(ref.set(data, SetOptions(merge: true)));
  }
}

/// Bumps one or more `/stats/daily-{day}` fields. See [bumpGlobalStats] for
/// the [txn]/best-effort contract.
void bumpDailyStats(
  FirebaseFirestore db,
  DateTime day,
  Map<String, int> deltas, {
  Transaction? txn,
}) {
  if (deltas.isEmpty) return;
  final ref = dailyStatsRef(db, day);
  final data = {
    for (final e in deltas.entries) e.key: FieldValue.increment(e.value),
  };
  if (txn != null) {
    txn.set(ref, data, SetOptions(merge: true));
  } else {
    unawaited(ref.set(data, SetOptions(merge: true)));
  }
}
