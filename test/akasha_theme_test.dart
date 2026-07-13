import 'package:akasha/models/library_theme.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all official presets produce a semantic palette', () {
    for (final preset in AkashaThemePreset.all) {
      final theme = AkashaTheme.forPreset(preset);
      final palette = theme.extension<AkashaPalette>();
      expect(palette, isNotNull, reason: preset.id);
      expect(
        AkashaPalette.contrastRatio(palette!.onAccent, palette.accent),
        greaterThanOrEqualTo(4.5),
        reason: preset.id,
      );
      for (final surface in [
        palette.background,
        palette.surface,
        palette.surfaceElevated,
        palette.menuSelected,
        palette.previewRail,
      ]) {
        expect(
          AkashaPalette.contrastRatio(palette.textMuted, surface),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.id} textMuted',
        );
      }
    }
  });

  test('app theme projects LibraryTheme into ThemeData and AkashaPalette', () {
    final theme = AkashaTheme.withAppTheme(
      ThemeData.dark(useMaterial3: true),
      LibraryTheme.sakura,
    );
    final palette = theme.extension<AkashaPalette>();

    expect(theme.scaffoldBackgroundColor, LibraryTheme.sakura.backgroundColor);
    expect(theme.colorScheme.primary, LibraryTheme.sakura.accentColor);
    expect(theme.colorScheme.secondary, LibraryTheme.sakura.accentColor);
    expect(palette, isNotNull);
    expect(palette!.background, LibraryTheme.sakura.backgroundColor);
    expect(palette.accent, LibraryTheme.sakura.accentColor);
    expect(palette.sidebar, isNot(LibraryTheme.classic.backgroundColor));
    expect(
      palette.bottomBar,
      isNot(
        Color.lerp(LibraryTheme.sakura.backgroundColor, Colors.black, 0.08),
      ),
    );
  });
}
