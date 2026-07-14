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
  final BoxFit heroFit;
  final AlignmentGeometry heroAlignment;

  const AkashaThemeAssets({
    this.backdropAssetPath,
    this.heroAssetPath,
    this.textureAssetPath,
    this.ambientAssetPath,
    this.backdropFit = BoxFit.cover,
    this.backdropAlignment = Alignment.center,
    this.heroFit = BoxFit.cover,
    this.heroAlignment = Alignment.center,
  });

  static const none = AkashaThemeAssets();

  Iterable<String> get paths sync* {
    if (backdropAssetPath case final path?) yield path;
    if (heroAssetPath case final path?) yield path;
    if (textureAssetPath case final path?) yield path;
    if (ambientAssetPath case final path?) yield path;
  }

  bool get isEmpty => paths.isEmpty;

  AkashaThemeAssets withoutAmbient() {
    return AkashaThemeAssets(
      backdropAssetPath: backdropAssetPath,
      heroAssetPath: heroAssetPath,
      textureAssetPath: textureAssetPath,
      backdropFit: backdropFit,
      backdropAlignment: backdropAlignment,
      heroFit: heroFit,
      heroAlignment: heroAlignment,
    );
  }
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

  AkashaThemeEffects copyWith({
    double? glowIntensity,
    double? shadowIntensity,
    double? overlayOpacity,
    double? particleIntensity,
  }) {
    return AkashaThemeEffects(
      glowIntensity: glowIntensity ?? this.glowIntensity,
      shadowIntensity: shadowIntensity ?? this.shadowIntensity,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      particleIntensity: particleIntensity ?? this.particleIntensity,
    );
  }
}

/// Theme-owned visual resources exposed through the root [ThemeData].
///
/// Feature widgets consume this extension instead of branching on a preset ID.
/// Assets and effect strength may change between theme packages; layout and
/// interaction geometry remain owned by the shared component.
@immutable
class AkashaThemeVisuals extends ThemeExtension<AkashaThemeVisuals> {
  final AkashaThemeAssets assets;
  final AkashaThemeEffects effects;

  const AkashaThemeVisuals({required this.assets, required this.effects});

  factory AkashaThemeVisuals.fromPreset(AkashaThemePreset preset) {
    return AkashaThemeVisuals(assets: preset.assets, effects: preset.effects);
  }

  static final fallback = AkashaThemeVisuals.fromPreset(
    AkashaThemePreset.classicDark,
  );

  AkashaThemeVisuals resolveForMotion({required bool reduceMotion}) {
    if (!reduceMotion) return this;
    return AkashaThemeVisuals(
      assets: assets.withoutAmbient(),
      effects: effects.copyWith(particleIntensity: 0),
    );
  }

  @override
  AkashaThemeVisuals copyWith({
    AkashaThemeAssets? assets,
    AkashaThemeEffects? effects,
  }) {
    return AkashaThemeVisuals(
      assets: assets ?? this.assets,
      effects: effects ?? this.effects,
    );
  }

  @override
  AkashaThemeVisuals lerp(
    covariant ThemeExtension<AkashaThemeVisuals>? other,
    double t,
  ) {
    if (other is! AkashaThemeVisuals) return this;
    return AkashaThemeVisuals(
      assets: t < 0.5 ? assets : other.assets,
      effects: AkashaThemeEffects(
        glowIntensity: _lerpDouble(
          effects.glowIntensity,
          other.effects.glowIntensity,
          t,
        ),
        shadowIntensity: _lerpDouble(
          effects.shadowIntensity,
          other.effects.shadowIntensity,
          t,
        ),
        overlayOpacity: _lerpDouble(
          effects.overlayOpacity,
          other.effects.overlayOpacity,
          t,
        ),
        particleIntensity: _lerpDouble(
          effects.particleIntensity,
          other.effects.particleIntensity,
          t,
        ),
      ),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AkashaThemeVisualsContext on BuildContext {
  AkashaThemeVisuals get akashaThemeVisuals =>
      Theme.of(this).extension<AkashaThemeVisuals>() ??
      AkashaThemeVisuals.fallback;

  AkashaThemeVisuals get resolvedAkashaThemeVisuals {
    final mediaQuery = MediaQuery.maybeOf(this);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    return akashaThemeVisuals.resolveForMotion(reduceMotion: reduceMotion);
  }
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

  /// Optional bitmap resources for a pack must stay under this namespace.
  /// A pack with no bitmap assets intentionally uses the shared code fallback.
  String get assetNamespace => 'assets/themes/$id/';

  bool get usesSharedArtworkFallback => assets.isEmpty;

  bool get hasValidAssetNamespace =>
      assets.paths.every((path) => path.startsWith(assetNamespace));

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
