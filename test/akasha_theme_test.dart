import 'package:akasha/models/library_theme.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all official presets produce a semantic palette', () {
    for (final preset in AkashaThemePreset.all) {
      final theme = AkashaTheme.forPreset(preset);
      final palette = theme.extension<AkashaPalette>();
      final visuals = theme.extension<AkashaThemeVisuals>();
      expect(palette, isNotNull, reason: preset.id);
      expect(visuals, isNotNull, reason: preset.id);
      expect(visuals!.assets, same(preset.assets), reason: preset.id);
      expect(visuals.effects, same(preset.effects), reason: preset.id);
      expect(preset.hasValidAssetNamespace, isTrue, reason: preset.id);
      expect(preset.assetNamespace, 'assets/themes/${preset.id}/');
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

  test('reduced motion removes ambient art and particle intensity only', () {
    const visuals = AkashaThemeVisuals(
      assets: AkashaThemeAssets(
        backdropAssetPath: 'assets/themes/fixture/backdrop.png',
        heroAssetPath: 'assets/themes/fixture/hero.png',
        textureAssetPath: 'assets/themes/fixture/texture.png',
        ambientAssetPath: 'assets/themes/fixture/ambient.png',
      ),
      effects: AkashaThemeEffects(
        glowIntensity: 0.7,
        shadowIntensity: 0.4,
        overlayOpacity: 0.5,
        particleIntensity: 0.9,
      ),
    );

    final resolved = visuals.resolveForMotion(reduceMotion: true);

    expect(resolved.assets.backdropAssetPath, visuals.assets.backdropAssetPath);
    expect(resolved.assets.heroAssetPath, visuals.assets.heroAssetPath);
    expect(resolved.assets.textureAssetPath, visuals.assets.textureAssetPath);
    expect(resolved.assets.ambientAssetPath, isNull);
    expect(resolved.effects.glowIntensity, visuals.effects.glowIntensity);
    expect(resolved.effects.shadowIntensity, visuals.effects.shadowIntensity);
    expect(resolved.effects.overlayOpacity, visuals.effects.overlayOpacity);
    expect(resolved.effects.particleIntensity, 0);
    expect(
      identical(visuals.resolveForMotion(reduceMotion: false), visuals),
      isTrue,
    );
  });

  test(
    'bundled themes own artwork while premium themes keep safe fallbacks',
    () {
      for (final preset in const [
        AkashaThemePreset.classicDark,
        AkashaThemePreset.midnightBlue,
      ]) {
        expect(preset.usesSharedArtworkFallback, isFalse, reason: preset.id);
        expect(preset.assets.backdropAssetPath, isNotNull, reason: preset.id);
        expect(preset.assets.heroAssetPath, isNotNull, reason: preset.id);
      }

      for (final preset in const [
        AkashaThemePreset.sakura,
        AkashaThemePreset.amethyst,
        AkashaThemePreset.nocturne,
      ]) {
        expect(preset.usesSharedArtworkFallback, isTrue, reason: preset.id);
      }
    },
  );

  testWidgets('bundled artwork paths resolve from the Flutter asset bundle', (
    tester,
  ) async {
    for (final preset in const [
      AkashaThemePreset.classicDark,
      AkashaThemePreset.midnightBlue,
    ]) {
      for (final path in preset.assets.paths) {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(0), reason: path);
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
