import 'package:flutter/material.dart';

import 'akasha_effect_spec.dart';

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

/// Theme-controlled backdrop effects.
@immutable
class AkashaBackdropEffects {
  final double glowIntensity;
  final double scrimOpacity;
  final double textureOpacity;
  final double ambientOpacity;

  const AkashaBackdropEffects({
    required this.glowIntensity,
    required this.scrimOpacity,
    required this.textureOpacity,
    required this.ambientOpacity,
  }) : assert(glowIntensity >= 0 && glowIntensity <= 1),
       assert(scrimOpacity >= 0 && scrimOpacity <= 1),
       assert(textureOpacity >= 0 && textureOpacity <= 1),
       assert(ambientOpacity >= 0 && ambientOpacity <= 1);

  AkashaBackdropEffects copyWith({
    double? glowIntensity,
    double? scrimOpacity,
    double? textureOpacity,
    double? ambientOpacity,
  }) {
    return AkashaBackdropEffects(
      glowIntensity: glowIntensity ?? this.glowIntensity,
      scrimOpacity: scrimOpacity ?? this.scrimOpacity,
      textureOpacity: textureOpacity ?? this.textureOpacity,
      ambientOpacity: ambientOpacity ?? this.ambientOpacity,
    );
  }

  AkashaBackdropEffects lerp(AkashaBackdropEffects other, double t) {
    return AkashaBackdropEffects(
      glowIntensity: _lerpDouble(glowIntensity, other.glowIntensity, t),
      scrimOpacity: _lerpDouble(scrimOpacity, other.scrimOpacity, t),
      textureOpacity: _lerpDouble(textureOpacity, other.textureOpacity, t),
      ambientOpacity: _lerpDouble(ambientOpacity, other.ambientOpacity, t),
    );
  }
}

/// Theme-controlled Home Hero effects.
@immutable
class AkashaHeroEffects {
  final double glowIntensity;
  final double shadowIntensity;

  const AkashaHeroEffects({
    required this.glowIntensity,
    required this.shadowIntensity,
  }) : assert(glowIntensity >= 0 && glowIntensity <= 1),
       assert(shadowIntensity >= 0 && shadowIntensity <= 1);

  AkashaHeroEffects lerp(AkashaHeroEffects other, double t) {
    return AkashaHeroEffects(
      glowIntensity: _lerpDouble(glowIntensity, other.glowIntensity, t),
      shadowIntensity: _lerpDouble(shadowIntensity, other.shadowIntensity, t),
    );
  }
}

/// Theme-controlled interaction emphasis without changing hit targets.
@immutable
class AkashaInteractionEffects {
  final double hoverIntensity;
  final double pressedIntensity;
  final double focusIntensity;

  const AkashaInteractionEffects({
    required this.hoverIntensity,
    required this.pressedIntensity,
    required this.focusIntensity,
  }) : assert(hoverIntensity >= 0 && hoverIntensity <= 1),
       assert(pressedIntensity >= 0 && pressedIntensity <= 1),
       assert(focusIntensity >= 0 && focusIntensity <= 1);

  static const neutral = AkashaInteractionEffects(
    hoverIntensity: 1,
    pressedIntensity: 1,
    focusIntensity: 1,
  );

  AkashaInteractionEffects lerp(AkashaInteractionEffects other, double t) {
    return AkashaInteractionEffects(
      hoverIntensity: _lerpDouble(hoverIntensity, other.hoverIntensity, t),
      pressedIntensity: _lerpDouble(
        pressedIntensity,
        other.pressedIntensity,
        t,
      ),
      focusIntensity: _lerpDouble(focusIntensity, other.focusIntensity, t),
    );
  }
}

/// Shared motion timing. Reduced motion resolves every decorative duration to
/// zero while leaving layout and input behavior unchanged.
@immutable
class AkashaMotionEffects {
  final Duration quickDuration;
  final Duration standardDuration;
  final Duration themeTransitionDuration;
  final Curve standardCurve;

  const AkashaMotionEffects({
    required this.quickDuration,
    required this.standardDuration,
    required this.themeTransitionDuration,
    required this.standardCurve,
  });

  static const standard = AkashaMotionEffects(
    quickDuration: Duration(milliseconds: 140),
    standardDuration: Duration(milliseconds: 200),
    themeTransitionDuration: Duration(milliseconds: 200),
    standardCurve: Curves.linear,
  );

  static const reduced = AkashaMotionEffects(
    quickDuration: Duration.zero,
    standardDuration: Duration.zero,
    themeTransitionDuration: Duration.zero,
    standardCurve: Curves.linear,
  );

  bool get isReduced =>
      quickDuration == Duration.zero &&
      standardDuration == Duration.zero &&
      themeTransitionDuration == Duration.zero;

  AkashaMotionEffects lerp(AkashaMotionEffects other, double t) {
    return AkashaMotionEffects(
      quickDuration: _lerpDuration(quickDuration, other.quickDuration, t),
      standardDuration: _lerpDuration(
        standardDuration,
        other.standardDuration,
        t,
      ),
      themeTransitionDuration: _lerpDuration(
        themeTransitionDuration,
        other.themeTransitionDuration,
        t,
      ),
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
    );
  }
}

/// Theme effects are grouped by the surface that consumes them. This prevents
/// a backdrop tuning value from silently changing Hero or interaction chrome.
@immutable
class AkashaThemeEffects {
  final AkashaBackdropEffects backdrop;
  final AkashaHeroEffects hero;
  final AkashaInteractionEffects interaction;
  final AkashaMotionEffects motion;
  final List<AkashaEffectSpec> extensions;

  const AkashaThemeEffects({
    required this.backdrop,
    required this.hero,
    this.interaction = AkashaInteractionEffects.neutral,
    this.motion = AkashaMotionEffects.standard,
    this.extensions = const [],
  });

  bool get hasValidExtensions => _hasUniqueEffectIds(extensions);

  static const neutral = AkashaThemeEffects(
    backdrop: AkashaBackdropEffects(
      glowIntensity: 0.2,
      scrimOpacity: 0.62,
      textureOpacity: 0.62,
      ambientOpacity: 0,
    ),
    hero: AkashaHeroEffects(glowIntensity: 0.2, shadowIntensity: 0.45),
  );

  AkashaThemeEffects copyWith({
    AkashaBackdropEffects? backdrop,
    AkashaHeroEffects? hero,
    AkashaInteractionEffects? interaction,
    AkashaMotionEffects? motion,
    List<AkashaEffectSpec>? extensions,
  }) {
    return AkashaThemeEffects(
      backdrop: backdrop ?? this.backdrop,
      hero: hero ?? this.hero,
      interaction: interaction ?? this.interaction,
      motion: motion ?? this.motion,
      extensions: extensions ?? this.extensions,
    );
  }

  AkashaThemeEffects resolveForMotion({required bool reduceMotion}) {
    if (!reduceMotion) return this;
    return copyWith(
      backdrop: backdrop.copyWith(ambientOpacity: 0),
      motion: AkashaMotionEffects.reduced,
      extensions: [
        for (final effect in extensions)
          if (!effect.requiresMotion) effect,
      ],
    );
  }

  AkashaThemeEffects lerp(AkashaThemeEffects other, double t) {
    return AkashaThemeEffects(
      backdrop: backdrop.lerp(other.backdrop, t),
      hero: hero.lerp(other.hero, t),
      interaction: interaction.lerp(other.interaction, t),
      motion: motion.lerp(other.motion, t),
      extensions: t < 0.5 ? extensions : other.extensions,
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

  static const fallback = AkashaThemeVisuals(
    assets: AkashaThemeAssets.none,
    effects: AkashaThemeEffects.neutral,
  );

  AkashaThemeVisuals resolveForMotion({required bool reduceMotion}) {
    if (!reduceMotion) return this;
    return AkashaThemeVisuals(
      assets: assets.withoutAmbient(),
      effects: effects.resolveForMotion(reduceMotion: true),
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
      effects: effects.lerp(other.effects, t),
    );
  }
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
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

Duration _lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: _lerpDouble(
      a.inMicroseconds.toDouble(),
      b.inMicroseconds.toDouble(),
      t,
    ).round(),
  );
}

bool _hasUniqueEffectIds(List<AkashaEffectSpec> effects) {
  final ids = <String>{};
  return effects.every((effect) => ids.add(effect.id));
}
