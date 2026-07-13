import 'package:flutter/material.dart';

/// Optional artwork layers owned by a visual theme preset.
///
/// A null path intentionally selects the shared gradient/solid fallback. Asset
/// availability must never affect navigation, layout, or feature visibility.
@immutable
class AkashaThemeAssets {
  final String? backdropAssetPath;
  final String? heroAssetPath;
  final String? textureAssetPath;
  final String? ambientAssetPath;
  final BoxFit backdropFit;
  final AlignmentGeometry backdropAlignment;

  const AkashaThemeAssets({
    this.backdropAssetPath,
    this.heroAssetPath,
    this.textureAssetPath,
    this.ambientAssetPath,
    this.backdropFit = BoxFit.cover,
    this.backdropAlignment = Alignment.center,
  });

  static const none = AkashaThemeAssets();
}

/// Theme-controlled atmospheric effects.
///
/// Every value is normalized to the inclusive 0-1 range. Geometry and motion
/// behavior remain component concerns and are deliberately absent here.
@immutable
class AkashaThemeEffects {
  final double glowIntensity;
  final double shadowIntensity;
  final double overlayOpacity;
  final double particleIntensity;

  const AkashaThemeEffects({
    required this.glowIntensity,
    required this.shadowIntensity,
    required this.overlayOpacity,
    required this.particleIntensity,
  }) : assert(glowIntensity >= 0 && glowIntensity <= 1),
       assert(shadowIntensity >= 0 && shadowIntensity <= 1),
       assert(overlayOpacity >= 0 && overlayOpacity <= 1),
       assert(particleIntensity >= 0 && particleIntensity <= 1);

  static const neutral = AkashaThemeEffects(
    glowIntensity: 0.2,
    shadowIntensity: 0.45,
    overlayOpacity: 0.62,
    particleIntensity: 0,
  );
}

/// A visual-only AKASHA theme preset.
///
/// Display names, prices, ownership, and commerce identifiers belong to the
/// theme catalog rather than this model.
@immutable
class AkashaThemePreset {
  final String id;
  final Color backgroundColor;
  final Color accentColor;
  final AkashaThemeAssets assets;
  final AkashaThemeEffects effects;

  const AkashaThemePreset({
    required this.id,
    required this.backgroundColor,
    required this.accentColor,
    required this.assets,
    required this.effects,
  });

  static const classicDark = AkashaThemePreset(
    id: 'classicDark',
    backgroundColor: Color(0xFF13131D),
    accentColor: Color(0xFF6C63FF),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects.neutral,
  );

  static const midnightBlue = AkashaThemePreset(
    id: 'midnightBlue',
    backgroundColor: Color(0xFF0D1B2A),
    accentColor: Color(0xFF64B5F6),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects(
      glowIntensity: 0.16,
      shadowIntensity: 0.48,
      overlayOpacity: 0.64,
      particleIntensity: 0,
    ),
  );

  /// Temporary color fallback until the final Sakura artwork pack is ready.
  static const sakura = AkashaThemePreset(
    id: 'sakura',
    backgroundColor: Color(0xFF2A1A22),
    accentColor: Color(0xFFF48FB1),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects.neutral,
  );

  /// Temporary color fallback until the final Amethyst artwork pack is ready.
  static const amethyst = AkashaThemePreset(
    id: 'amethyst',
    backgroundColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFB39DDB),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects.neutral,
  );

  /// Neutral fallback only. Nocturne's final visual direction is undecided.
  static const nocturne = AkashaThemePreset(
    id: 'nocturne',
    backgroundColor: Color(0xFF13131D),
    accentColor: Color(0xFF6C63FF),
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects.neutral,
  );

  static const List<AkashaThemePreset> all = [
    classicDark,
    midnightBlue,
    sakura,
    amethyst,
    nocturne,
  ];

  static AkashaThemePreset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
