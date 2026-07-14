import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_theme_preset.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';
import 'home_dashboard_summary.dart';

/// Home archive Hero with a shared content slot and theme-owned artwork slot.
///
/// The summary is built only from real local archive data. A theme may replace
/// the artwork and effect strength, but never this component's geometry,
/// information order, empty state, or interaction behavior.
class HomeDashboardHero extends StatelessWidget {
  const HomeDashboardHero({
    super.key,
    required this.summary,
    required this.onStartRecording,
  });

  static const panelKey = ValueKey('home-dashboard-hero-panel');
  static const artworkKey = ValueKey('home-dashboard-hero-artwork');
  static const statsKey = ValueKey('home-dashboard-hero-stats');
  static const emptyActionKey = ValueKey('home-dashboard-hero-empty-action');
  static ValueKey<String> statKey(String id) =>
      ValueKey<String>('home-dashboard-hero-stat-$id');

  static const _brandMarkAsset = 'assets/branding/akasha_mark.png';
  static const _wideBreakpoint = 820.0;
  static const _minHeight = 216.0;
  static const _heroRadius = 16.0;

  final HomeDashboardSummary summary;
  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final visuals = context.resolvedAkashaThemeVisuals;
    final title = l10n?.dashboardHeroTitle ?? '기록하고, 연결하고, 발견하세요';
    final subtitle =
        l10n?.dashboardHeroSubtitle ??
        '작품, 사람, 사건, 개념을 기록하면 연결이 생기고 새로운 발견으로 이어집니다.';

    return SizedBox(
      key: panelKey,
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
                      color: palette.shadow.withValues(
                        alpha: 0.16 + visuals.effects.shadowIntensity * 0.16,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _HeroWash(
                          palette: palette,
                          glowIntensity: visuals.effects.glowIntensity,
                          wide: wide,
                        ),
                      ),
                    ),
                    if (wide)
                      Positioned(
                        key: artworkKey,
                        left: constraints.maxWidth * 0.55,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: _HeroArtwork(
                            palette: palette,
                            visuals: visuals,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AkashaSpacing.xl,
                        vertical: AkashaSpacing.xl,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: wide ? 0.62 : 1,
                          alignment: Alignment.centerLeft,
                          child: _HeroCopy(
                            title: title,
                            subtitle: subtitle,
                            summary: summary,
                            onStartRecording: onStartRecording,
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
    required this.summary,
    required this.onStartRecording,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final HomeDashboardSummary summary;
  final VoidCallback onStartRecording;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AkashaTypography.dashboardHero.copyWith(
            height: 1.2,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: AkashaSpacing.sm),
        Text(
          subtitle,
          style: AkashaTypography.body.copyWith(
            color: palette.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AkashaSpacing.lg),
        if (summary.isEmpty)
          FilledButton.icon(
            key: HomeDashboardHero.emptyActionKey,
            onPressed: onStartRecording,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n?.dashboardHeroStartAction ?? '첫 기록 시작'),
          )
        else
          _HeroStats(summary: summary, palette: palette),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.summary, required this.palette});

  final HomeDashboardSummary summary;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPattern(locale);
    final stats = [
      (
        id: 'records',
        icon: Icons.inventory_2_outlined,
        label: l10n?.dashboardHeroArchiveRecords ?? '아카이브 기록',
        value: summary.archiveRecordCount,
      ),
      (
        id: 'entities',
        icon: Icons.hub_outlined,
        label: l10n?.dashboardHeroEntities ?? '엔티티',
        value: summary.entityCount,
      ),
      (
        id: 'collections',
        icon: Icons.collections_bookmark_outlined,
        label: l10n?.dashboardHeroCollections ?? '컬렉션',
        value: summary.collectionCount,
      ),
      (
        id: 'tags',
        icon: Icons.sell_outlined,
        label: l10n?.dashboardHeroTags ?? '태그',
        value: summary.tagCount,
      ),
    ];

    return LayoutBuilder(
      key: HomeDashboardHero.statsKey,
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 500 ? 4 : 2;
        const gap = AkashaSpacing.sm;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                key: HomeDashboardHero.statKey(stat.id),
                width: tileWidth,
                child: _HeroStatTile(
                  icon: stat.icon,
                  label: stat.label,
                  value: format.format(stat.value),
                  palette: palette,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.borderSubtle(0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AkashaSpacing.sm + 2,
            vertical: AkashaSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: palette.accent),
              const SizedBox(width: AkashaSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AkashaTypography.micro.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AkashaTypography.dashboardPanelTitle.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroWash extends StatelessWidget {
  const _HeroWash({
    required this.palette,
    required this.glowIntensity,
    required this.wide,
  });

  final AkashaPalette palette;
  final double glowIntensity;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final accentMix = (0.12 + glowIntensity * 0.3).clamp(0.12, 0.42);
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
              wide ? accentMix * 0.72 : accentMix,
            )!,
            Color.lerp(
              palette.surfaceElevated,
              palette.accent,
              wide ? accentMix * 0.46 : accentMix * 0.58,
            )!,
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.palette, required this.visuals});

  final AkashaPalette palette;
  final AkashaThemeVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final assetPath = visuals.assets.heroAssetPath;
    if (assetPath == null) {
      return _HeroBrandVisual(
        palette: palette,
        glowIntensity: visuals.effects.glowIntensity,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: visuals.assets.heroFit,
          alignment: visuals.assets.heroAlignment,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => _HeroBrandVisual(
            palette: palette,
            glowIntensity: visuals.effects.glowIntensity,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.surfaceElevated,
                palette.surfaceElevated.withValues(alpha: 0.18),
                palette.surfaceElevated.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared fallback used until a theme package supplies final Hero artwork.
class _HeroBrandVisual extends StatelessWidget {
  const _HeroBrandVisual({required this.palette, required this.glowIntensity});

  final AkashaPalette palette;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }
        final markSize = (h * 0.62).clamp(104.0, 148.0);
        final outer = markSize * 1.58;
        final inner = markSize * 1.18;
        final glowAlpha = (0.18 + glowIntensity * 0.5).clamp(0.18, 0.68);

        return Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, 0),
                    radius: 0.92,
                    colors: [
                      palette.accent.withValues(alpha: glowAlpha),
                      palette.accentSoft.withValues(alpha: glowAlpha * 0.42),
                      palette.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: outer,
              height: outer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.42),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.borderSubtle(0.52)),
              ),
            ),
            Image.asset(
              HomeDashboardHero._brandMarkAsset,
              width: markSize,
              height: markSize,
              fit: BoxFit.contain,
              semanticLabel: 'AKASHA',
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
