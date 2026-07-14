import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/theme/akasha_palette.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all official presets produce a semantic palette', () {
    for (final preset in AkashaThemeRegistry.presets) {
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

  test('reduced motion removes ambient art and decorative motion only', () {
    const visuals = AkashaThemeVisuals(
      assets: AkashaThemeAssets(
        backdropAssetPath: 'assets/themes/fixture/backdrop.png',
        heroAssetPath: 'assets/themes/fixture/hero.png',
        textureAssetPath: 'assets/themes/fixture/texture.png',
        ambientAssetPath: 'assets/themes/fixture/ambient.png',
      ),
      effects: AkashaThemeEffects(
        backdrop: AkashaBackdropEffects(
          glowIntensity: 0.7,
          scrimOpacity: 0.5,
          textureOpacity: 0.3,
          ambientOpacity: 0.9,
        ),
        hero: AkashaHeroEffects(glowIntensity: 0.6, shadowIntensity: 0.4),
      ),
    );

    final resolved = visuals.resolveForMotion(reduceMotion: true);

    expect(resolved.assets.backdropAssetPath, visuals.assets.backdropAssetPath);
    expect(resolved.assets.heroAssetPath, visuals.assets.heroAssetPath);
    expect(resolved.assets.textureAssetPath, visuals.assets.textureAssetPath);
    expect(resolved.assets.ambientAssetPath, isNull);
    expect(
      resolved.effects.backdrop.glowIntensity,
      visuals.effects.backdrop.glowIntensity,
    );
    expect(
      resolved.effects.backdrop.scrimOpacity,
      visuals.effects.backdrop.scrimOpacity,
    );
    expect(
      resolved.effects.backdrop.textureOpacity,
      visuals.effects.backdrop.textureOpacity,
    );
    expect(resolved.effects.backdrop.ambientOpacity, 0);
    expect(resolved.effects.hero, same(visuals.effects.hero));
    expect(resolved.effects.interaction, same(visuals.effects.interaction));
    expect(resolved.effects.motion.isReduced, isTrue);
    expect(
      identical(visuals.resolveForMotion(reduceMotion: false), visuals),
      isTrue,
    );
  });

  test('surface effect groups can evolve without cross-coupling', () {
    const original = AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0.2,
        scrimOpacity: 0.3,
        textureOpacity: 0.4,
        ambientOpacity: 0.5,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0.6, shadowIntensity: 0.7),
      interaction: AkashaInteractionEffects(
        hoverIntensity: 0.8,
        pressedIntensity: 0.7,
        focusIntensity: 0.6,
      ),
      motion: AkashaMotionEffects(
        quickDuration: Duration(milliseconds: 100),
        standardDuration: Duration(milliseconds: 180),
        themeTransitionDuration: Duration(milliseconds: 240),
        standardCurve: Curves.easeOut,
      ),
    );

    final changed = original.copyWith(
      backdrop: original.backdrop.copyWith(scrimOpacity: 0.9),
    );

    expect(changed.backdrop.scrimOpacity, 0.9);
    expect(changed.hero, same(original.hero));
    expect(changed.interaction, same(original.interaction));
    expect(changed.motion, same(original.motion));
  });

  test('interaction effects project into root Material feedback colors', () {
    const preset = AkashaThemePreset(
      id: 'interactionFixture',
      backgroundColor: Color(0xFF101018),
      accentColor: Color(0xFF8070FF),
      assets: AkashaThemeAssets.none,
      effects: AkashaThemeEffects(
        backdrop: AkashaBackdropEffects(
          glowIntensity: 0,
          scrimOpacity: 0,
          textureOpacity: 0,
          ambientOpacity: 0,
        ),
        hero: AkashaHeroEffects(glowIntensity: 0, shadowIntensity: 0),
        interaction: AkashaInteractionEffects(
          hoverIntensity: 0.5,
          pressedIntensity: 0.25,
          focusIntensity: 0.75,
        ),
      ),
    );

    final palette = AkashaPalette.fromPreset(preset);
    final theme = AkashaTheme.forPreset(preset);

    expect(theme.focusColor, palette.focusRing.withValues(alpha: 0.28 * 0.75));
    expect(
      theme.hoverColor,
      Color.lerp(Colors.transparent, palette.hoverSurface, 0.5),
    );
    expect(
      theme.splashColor,
      Color.lerp(Colors.transparent, palette.accentSoft, 0.25),
    );
  });

  test('all official themes own namespaced artwork', () {
    for (final preset in AkashaThemeRegistry.presets) {
      expect(preset.usesSharedArtworkFallback, isFalse, reason: preset.id);
      expect(preset.assets.backdropAssetPath, isNotNull, reason: preset.id);
      expect(preset.assets.heroAssetPath, isNotNull, reason: preset.id);
      expect(preset.hasValidAssetNamespace, isTrue, reason: preset.id);
    }
  });

  testWidgets('official artwork paths resolve from the Flutter asset bundle', (
    tester,
  ) async {
    for (final preset in AkashaThemeRegistry.presets) {
      for (final path in preset.assets.paths) {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(0), reason: path);
      }
    }
  });

  test('app theme projects a registry preset into ThemeData and palette', () {
    final sakura = AkashaThemeRegistry.sakuraPreset;
    final classic = AkashaThemeRegistry.classicDarkPreset;
    final theme = AkashaTheme.withPreset(
      ThemeData.dark(useMaterial3: true),
      sakura,
    );
    final palette = theme.extension<AkashaPalette>();

    expect(theme.scaffoldBackgroundColor, sakura.backgroundColor);
    expect(theme.colorScheme.primary, sakura.accentColor);
    expect(theme.colorScheme.secondary, sakura.accentColor);
    expect(palette, isNotNull);
    expect(palette!.background, sakura.backgroundColor);
    expect(palette.accent, sakura.accentColor);
    expect(palette.sidebar, isNot(classic.backgroundColor));
    expect(
      palette.bottomBar,
      isNot(Color.lerp(sakura.backgroundColor, Colors.black, 0.08)),
    );
  });
}
