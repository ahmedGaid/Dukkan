import '../../../domain/config/entities/feature_flags.dart';

class FeatureFlagsModel extends FeatureFlags {
  const FeatureFlagsModel({required super.flags});

  factory FeatureFlagsModel.fromFirestore(Map<String, dynamic> data) {
    final raw = data['flags'] as Map<String, dynamic>? ?? const {};
    return FeatureFlagsModel(
      flags: raw.map((key, value) => MapEntry(key, value as bool? ?? false)),
    );
  }
}
