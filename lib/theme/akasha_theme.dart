import 'package:flutter/material.dart';

import '../models/library_theme.dart';
import 'akasha_palette.dart';
import 'akasha_theme_preset.dart';

/// AKASHA 글로벌 Material 3 다크 테마.
abstract final class AkashaTheme {
  static ThemeData dark({LibraryTheme appTheme = LibraryTheme.classic}) {
    final base = ThemeData.dark(useMaterial3: true);
    return withAppTheme(base, appTheme);
  }

  static ThemeData forPreset(AkashaThemePreset preset) {
    return withPreset(ThemeData.dark(useMaterial3: true), preset);
  }

  static ThemeData withAppTheme(ThemeData base, LibraryTheme appTheme) {
    return withPreset(base, appTheme.preset);
  }

  static ThemeData withPreset(ThemeData base, AkashaThemePreset preset) {
    final palette = AkashaPalette.fromPreset(preset);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: palette.accent,
          secondary: palette.accent,
          surface: palette.surface,
          surfaceContainerHighest: palette.surfaceElevated,
          onPrimary: palette.onAccent,
          onSecondary: palette.onAccent,
          onSurface: palette.textPrimary,
          error: palette.danger,
        );

    final textTheme = base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
      decorationColor: palette.accent,
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      focusColor: palette.focusRing.withValues(alpha: 0.28),
      hoverColor: palette.hoverSurface,
      splashColor: palette.accentSoft,
      extensions: [
        ...base.extensions.values.where((ext) => ext is! AkashaPalette),
        palette,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: palette.surfaceElevated),
      dividerTheme: DividerThemeData(color: palette.borderSubtle(0.32)),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        modalBackgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.searchField,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.borderSubtle(0.34)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: palette.focusRing, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: palette.accentSoft,
        checkmarkColor: palette.accent,
        side: BorderSide(color: palette.borderSubtle(0.24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.borderSubtle(0.55)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.accent),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.accent,
        selectionColor: palette.accentSoft,
        selectionHandleColor: palette.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    );
  }
}
