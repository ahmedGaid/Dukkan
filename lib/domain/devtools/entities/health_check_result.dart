import 'package:equatable/equatable.dart';

/// One row of the devtools health-check panel (FC15). [id] is a stable key
/// the UI maps to a localized label — never shown raw — same convention as
/// `ConsoleSection.labelKey`.
class HealthCheckResult extends Equatable {
  const HealthCheckResult({
    required this.id,
    required this.ok,
    required this.latencyMs,
    this.errorMessage,
  });

  final String id;
  final bool ok;
  final int latencyMs;
  final String? errorMessage;

  @override
  List<Object?> get props => [id, ok, latencyMs, errorMessage];
}
