import 'package:flutter/material.dart';

import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';

/// Home top Hero panel: shared copy + theme-aware visual slot.
///
/// Wide: left copy + right brand visual.
/// Narrow: copy only; wash absorbs the visual. No arbitrary maxWidth shrink.
class HomeDashboardHero extends StatelessWidget {
  const HomeDashboardHero({super.key});

  static const _brandMarkAsset = 'assets/branding/akasha_mark.png';
  /// Logical px. High-DPI desktop windows often land near 480-560.
  static const _wideBreakpoint = 480.0;
  static const _minHeight = 132.0;
  static const _heroRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final title =
        l10n?.dashboardHeroTitle ?? '기록하고, 연결하고, 발견하세요';
    final subtitle =
        l10n?.dashboardHeroSubtitle ??
        '작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.';

    // Fill Home column width (infinity inside existing Home padding).
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          return ClipRRect(
            borderRadius: BorderRadius.circular(_heroRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(_heroRadius),
                  border: Border.all(color: palette.borderSubtle(0.34)),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _HeroWash(palette: palette, wide: wide),
                      ),
                    ),
                    // Windows: flex/FractionallySizedBox slots inside this Stack
                    // often paint empty; fixed left + Center + SizedBox works.
                    if (wide)
                      Positioned(
                        left: 280,
                        top: 0,
                        right: 24,
                        bottom: 0,
                        child: Center(
                          child: SizedBox(
                            width: 280,
                            height: 124,
                            child: IgnorePointer(
                              child: _HeroBrandVisual(palette: palette),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AkashaSpacing.xl,
                        vertical: AkashaSpacing.lg + 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: wide ? 0.58 : 1,
                          alignment: Alignment.centerLeft,
                          child: _HeroCopy(
                            title: title,
                            subtitle: subtitle,
                            palette: palette,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AkashaTypography.dashboardHero.copyWith(
            height: 1.25,
            color: palette.textPrimary,
          ),
        ),
        SizedBox(height: AkashaSpacing.sm),
        Text(
          subtitle,
          style: AkashaTypography.body.copyWith(
            color: palette.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Soft accent wash; narrow absorbs the visual role here.
class _HeroWash extends StatelessWidget {
  const _HeroWash({required this.palette, required this.wide});

  final AkashaPalette palette;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            palette.surfaceElevated,
            Color.lerp(
              palette.surfaceElevated,
              palette.accentSoft,
              wide ? 0.35 : 0.55,
            )!,
            Color.lerp(
              palette.surfaceElevated,
              palette.accent,
              wide ? 0.18 : 0.22,
            )!.withValues(alpha: wide ? 0.55 : 0.7),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// Wide-only brand visual: large mark + two orbits.
/// Mark failure: orbits/wash only (no icon fallback centerpiece).
class _HeroBrandVisual extends StatelessWidget {
  const _HeroBrandVisual({required this.palette});

  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }
        final markSize = (h * 0.78).clamp(96.0, 148.0);
        final outer = markSize * 1.45;
        final inner = markSize * 1.15;

        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.35, 0),
                    radius: 0.95,
                    colors: [
                      palette.accent.withValues(alpha: 0.36),
                      palette.accentSoft.withValues(alpha: 0.14),
                      palette.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: outer,
                height: outer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: inner,
                height: inner,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.borderSubtle(0.55),
                    width: 1,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                HomeDashboardHero._brandMarkAsset,
                width: markSize,
                height: markSize,
                fit: BoxFit.contain,
                semanticLabel: 'AKASHA',
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
