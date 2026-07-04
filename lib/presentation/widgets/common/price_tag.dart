import 'package:flutter/material.dart';

import '../../../core/money.dart';

/// Renders integer piasters as a formatted price (Arabic-Indic + "ج.م" or
/// Western + "EGP", per locale). The ONE way prices show in the UI — consumes
/// minor units, never a double (money hard rule).
class PriceTag extends StatelessWidget {
  const PriceTag(this.minor, {super.key, this.style});

  /// Price in integer piasters.
  final int minor;

  /// Overrides the default (titleSmall, deep-green/strong). Colour is left to
  /// the theme's onSurface unless the caller wants an accent.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    return Text(
      Money.format(minor, languageCode: locale),
      style: style ??
          text.titleSmall?.copyWith(color: scheme.primary),
    );
  }
}
