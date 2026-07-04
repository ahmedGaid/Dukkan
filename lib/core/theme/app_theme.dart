import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles ThemeData from the brand tokens (Docs/Brand/BRAND.md).
/// Dark mode: mint (primaryBright) becomes primary; deep green recedes.
abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      secondary: AppColors.primaryBright,
      onSecondary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.primary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.outline,
      error: AppColors.error,
      onError: AppColors.surface,
    );

    return _base(colorScheme, locale, scaffoldBg: AppColors.surfaceVariant);
  }

  static ThemeData dark(Locale locale) {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primaryBright,
      onPrimary: AppColors.darkBg,
      secondary: AppColors.awning,
      onSecondary: AppColors.darkBg,
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFF4F7F5),
      surfaceContainerHighest: AppColors.darkCard,
      outline: Color(0xFF2A362F),
      error: AppColors.error,
      onError: AppColors.darkBg,
    );

    return _base(colorScheme, locale, scaffoldBg: AppColors.darkBg);
  }

  static ThemeData _base(
    ColorScheme colorScheme,
    Locale locale, {
    required Color scaffoldBg,
  }) {
    final textTheme = AppTypography.textTheme(locale, colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      fontFamilyFallback: textTheme.bodyMedium?.fontFamilyFallback,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondary.withValues(alpha: 0.16),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.bodySmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.6),
          );
        }),
      ),
    );
  }
}
