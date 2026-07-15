import 'package:equatable/equatable.dart';

/// One registered migration paired with whether it has already run —
/// [description] is plain Arabic text (not an l10n key, unlike
/// `HealthCheckResult.id`), since migrations are dev-authored one-offs, not
/// user-facing product copy that needs an English parity string.
class MigrationStatus extends Equatable {
  const MigrationStatus({
    required this.id,
    required this.description,
    required this.applied,
  });

  final String id;
  final String description;
  final bool applied;

  @override
  List<Object?> get props => [id, description, applied];
}
