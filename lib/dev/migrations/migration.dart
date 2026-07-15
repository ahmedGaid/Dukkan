import 'package:cloud_firestore/cloud_firestore.dart';

/// One idempotent data fix, run from the console devtools page (FC15).
/// [run] must be safe to call twice — devtools tracks applied ids in
/// `/config/migrations`, but a migration should never assume that tracking
/// is perfectly in sync (e.g. it ran, then the write recording it failed).
class Migration {
  const Migration({required this.id, required this.description, required this.run});

  final String id;
  final String description;
  final Future<void> Function(FirebaseFirestore db) run;
}
