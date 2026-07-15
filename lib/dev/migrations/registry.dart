import 'migration.dart';

/// Every migration devtools can run, oldest first. A migration is added here
/// once and never removed (even after every doc is fixed) — the `applied`
/// list on `/config/migrations` is the historical record of what ran.
final migrations = <Migration>[
  Migration(
    id: '001_backfill_shops_status',
    description: 'يضبط حالة "نشط" لأي متجر قديم بدون حقل status',
    run: (db) async {
      final snap = await db.collection('shops').get();
      for (final doc in snap.docs) {
        if (doc.data()['status'] == null) {
          await doc.reference.update({'status': 'active'});
        }
      }
    },
  ),
];
