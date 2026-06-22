import 'package:flutter/material.dart';

import 'akasha_colors.dart';

/// AKASHA 글로벌 Material 3 다크 테마.
abstract final class AkashaTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AkashaColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AkashaColors.accent,
      secondary: AkashaColors.accent,
      surface: AkashaColors.surface,
      onPrimary: Colors.white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AkashaColors.background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AkashaColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AkashaColors.surfaceElevated,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.withValues(alpha: 0.15),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AkashaColors.accent.withValues(alpha: 0.2),
        checkmarkColor: AkashaColors.accent,
        side: BorderSide(color: AkashaColors.borderSubtle(0.12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AkashaColors.accent,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AkashaColors.accent,
      ),
    );
  }
}
