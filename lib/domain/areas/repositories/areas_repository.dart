import '../entities/area.dart';

/// Areas boundary — one-shot read of the fixed, seed-managed district list.
/// Not a stream: `/areas` never changes at runtime (only via re-seed), same
/// contract as `TaxonomyRepository.getTaxonomy`.
abstract class AreasRepository {
  /// All areas in `sort` order. Online → remote read (cached after); offline
  /// → last cached read.
  Future<List<Area>> getAreas();
}
