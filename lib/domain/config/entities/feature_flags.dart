import 'package:equatable/equatable.dart';

/// `/config/flags` (M12) — founder-managed on/off switches, console-editable.
/// No app code depends on a specific key yet; [flag] is the consumer contract
/// future sessions build against.
class FeatureFlags extends Equatable {
  const FeatureFlags({this.flags = const {}});

  final Map<String, bool> flags;

  /// Looks up [key], defaulting to [orElse] when absent — a flag an older
  /// app build has never heard of is simply off, never a crash.
  bool flag(String key, {bool orElse = false}) => flags[key] ?? orElse;

  @override
  List<Object?> get props => [flags];
}
