import 'package:flutter/material.dart';

/// Canon: Docs/Brand/BRAND.md — IBM Plex Sans Arabic (ar) + Inter (en).
/// Titles weight 600, body weight 400. No third font, ever.
abstract final class AppTypography {
  static const arabicFamily = 'IBMPlexSansArabic';
  static const latinFamily = 'Inter';

  static TextTheme textTheme(Locale locale, Color color) {
    final isArabic = locale.languageCode == 'ar';
    final family = isArabic ? arabicFamily : latinFamily;
    final fallback = [isArabic ? latinFamily : arabicFamily];

    TextStyle style(double size, FontWeight weight) => TextStyle(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontSize: size,
          fontWeight: weight,
          color: color,
        );

    return TextTheme(
      titleLarge: style(22, FontWeight.w600),
      titleMedium: style(18, FontWeight.w600),
      titleSmall: style(15, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400),
      labelLarge: style(15, FontWeight.w600),
    );
  }
}
