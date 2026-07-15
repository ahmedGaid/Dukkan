import '../entities/health_check_result.dart';
import '../entities/migration_status.dart';

/// Boundary for the console devtools page (`/console/devtools`, FC15,
/// `system.tools`). Mixes Worker-routed ops (fake data — the `/users`/
/// `/orders` create rules have no staff bypass) with Firestore-direct ones
/// (seed, caches, migrations — all reachable via the founder's `*`
/// wildcard through existing `hasPerm` branches), same mixed contract as
/// `AdminOrdersRepository`.
abstract class DevToolsRepository {
  Future<List<HealthCheckResult>> runHealthChecks();

  /// Re-runs `lib/dev/seed.dart`'s `runSeed` in place. Ends signed out, same
  /// as the CLI path — see `seed.dart`'s doc comment.
  Future<void> runDemoSeed({
    required bool rbac,
    required bool catalog,
    required bool customers,
  });

  /// `/users` docs only, no Auth account. Returns the created uids.
  Future<List<String>> generateFakeCustomers(int count);

  /// [products]/[customerUids] are supplied by the caller (already loaded
  /// for the console's own board views) — this never queries for them itself.
  Future<int> generateFakeOrders({
    required String shopId,
    required List<Map<String, dynamic>> products,
    required List<String> customerUids,
    required int count,
  });

  /// Deletes every `fake: true` doc across `/users` and `/orders`. Returns
  /// the count removed.
  Future<int> cleanupFakeData();

  /// Clears every local cache datasource + the memoized platform
  /// config/flags, so the next read on this device hits remote.
  Future<void> clearCaches();

  Future<List<MigrationStatus>> getMigrations();

  Future<void> runMigration(String id);
}
