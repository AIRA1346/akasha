import 'package:flutter/material.dart';

import '../theme/akasha_theme_preset.dart';

/// Paints a theme-owned backdrop behind [child] without changing its geometry.
///
/// Decorative layers never participate in hit testing. When an artwork asset
/// is absent or fails to load, the preset-derived gradient remains visible.
/// Ambient artwork is omitted when the platform requests reduced motion so an
/// animated image asset cannot introduce motion in that mode.
class AkashaThemeBackdrop extends StatelessWidget {
  final AkashaThemePreset preset;
  final Widget child;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  final bool showTexture;
  final bool showAmbient;

  const AkashaThemeBackdrop({
    super.key,
    required this.preset,
    required this.child,
    this.fit,
    this.alignment,
    this.showTexture = true,
    this.showAmbient = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    final resolvedFit = fit ?? preset.assets.backdropFit;
    final resolvedAlignment = alignment ?? preset.assets.backdropAlignment;
    final visuals = AkashaThemeVisuals.fromPreset(
      preset,
    ).resolveForMotion(reduceMotion: reduceMotion || !showAmbient);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: _ThemeDecoration(
              preset: preset,
              visuals: visuals,
              fit: resolvedFit,
              alignment: resolvedAlignment,
              showTexture: showTexture,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ThemeDecoration extends StatelessWidget {
  final AkashaThemePreset preset;
  final AkashaThemeVisuals visuals;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool showTexture;

  const _ThemeDecoration({
    required this.preset,
    required this.visuals,
    required this.fit,
    required this.alignment,
    required this.showTexture,
  });

  @override
  Widget build(BuildContext context) {
    final assets = visuals.assets;
    final effects = visuals.effects;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                preset.backgroundColor,
                Color.lerp(
                      preset.backgroundColor,
                      preset.accentColor,
                      (effects.glowIntensity * 0.16).clamp(0.0, 0.16),
                    ) ??
                    preset.backgroundColor,
                preset.backgroundColor,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        if (assets.backdropAssetPath case final path?)
          _BackdropImage(path: path, fit: fit, alignment: alignment),
        if (showTexture)
          if (assets.textureAssetPath case final path?)
            Opacity(
              opacity: effects.overlayOpacity.clamp(0.0, 1.0),
              child: _BackdropImage(path: path, fit: fit, alignment: alignment),
            ),
        if (assets.ambientAssetPath case final path?)
          Opacity(
            opacity: effects.particleIntensity.clamp(0.0, 1.0),
            child: _BackdropImage(path: path, fit: fit, alignment: alignment),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: preset.backgroundColor.withValues(
              alpha: effects.overlayOpacity.clamp(0.0, 1.0),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  const _BackdropImage({
    required this.path,
    required this.fit,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
