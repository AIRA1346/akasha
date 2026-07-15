import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/theme_catalog.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_theme_preset.dart';
import '../theme/akasha_theme_registry.dart';
import '../utils/app_l10n.dart';

/// Discoverable gallery for every official app theme.
///
/// The gallery never invents prices or purchase actions. Access and offer state
/// come from separate contracts so planned premium themes can remain visible
/// while commerce is disabled.
Future<String?> showAkashaThemePicker(
  BuildContext context, {
  required String currentThemeId,
  required Map<String, ThemeAccessState> accessByPresetId,
}) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      final palette = ctx.akashaPalette;
      final definitions = AkashaThemeRegistry.all;
      final availableCount = definitions.where((definition) {
        return (accessByPresetId[definition.id] ??
                _fallbackAccess(definition.catalog))
            .grantsAccess;
      }).length;
      final viewport = MediaQuery.sizeOf(ctx);
      final dialogHeight = (viewport.height - 48).clamp(420.0, 680.0);

      return Dialog(
        backgroundColor: palette.surfaceElevated,
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          key: const ValueKey('akasha-theme-gallery'),
          width: 820,
          height: dialogHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.appThemeGalleryTitle ?? '테마 갤러리',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            l10n?.appThemeGallerySubtitle ??
                                '공식 테마를 한곳에서 살펴보세요. 유료 테마도 판매 전부터 확인할 수 있습니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.appThemeGalleryAvailableCount(
                                  availableCount,
                                  definitions.length,
                                ) ??
                                '전체 ${definitions.length}개 중 $availableCount개 사용 가능',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n?.appPreferencesClose ?? '닫기',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.borderSubtle(0.55)),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: definitions.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 262,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final definition = definitions[index];
                    final access =
                        accessByPresetId[definition.id] ??
                        _fallbackAccess(definition.catalog);
                    return _ThemeGalleryCard(
                      definition: definition,
                      access: access,
                      selected: currentThemeId == definition.id,
                      l10n: l10n,
                      onSelect: access.grantsAccess
                          ? () => Navigator.pop(ctx, definition.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

ThemeAccessState _fallbackAccess(ThemeCatalogEntry entry) =>
    entry.isBundled ? ThemeAccessState.free : ThemeAccessState.unavailable;

class _ThemeGalleryCard extends StatelessWidget {
  const _ThemeGalleryCard({
    required this.definition,
    required this.access,
    required this.selected,
    required this.l10n,
    required this.onSelect,
  });

  final AkashaThemeDefinition definition;
  final ThemeAccessState access;
  final bool selected;
  final AppLocalizations? l10n;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final preset = definition.preset;
    final status = _themeStatusLabel(l10n, definition.catalog, access);

    return Semantics(
      button: onSelect != null,
      enabled: onSelect != null,
      selected: selected,
      label: '${_localizedThemeName(l10n, definition)}, $status',
      child: Material(
        color: selected
            ? preset.accentColor.withValues(alpha: 0.10)
            : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? preset.accentColor : palette.borderSubtle(0.62),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ThemeArtwork(preset: preset),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB8000000)],
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _ThemeBadge(
                          label: l10n?.themeStatusCurrent ?? '사용 중',
                          color: preset.accentColor,
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Text(
                        _localizedThemeName(l10n, definition),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeBadge(
                            label: status,
                            color: _statusColor(
                              palette,
                              access,
                              definition.catalog,
                            ),
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          access.grantsAccess
                              ? (selected
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded)
                              : definition.catalog.offerState ==
                                    ThemeOfferState.planned
                              ? Icons.schedule_rounded
                              : Icons.lock_outline_rounded,
                          size: 18,
                          color: access.grantsAccess
                              ? preset.accentColor
                              : palette.textMuted,
                        ),
                      ],
                    ),
                    if (_themePriceLabel(l10n, definition.catalog)
                        case final priceLabel?) ...[
                      const SizedBox(height: 7),
                      Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _ThemeArtwork extends StatelessWidget {
  const _ThemeArtwork({required this.preset});

  final AkashaThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final asset = preset.assets.heroAssetPath;
    if (asset == null) return _ThemeArtworkFallback(preset: preset);
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => _ThemeArtworkFallback(preset: preset),
    );
  }
}

class _ThemeArtworkFallback extends StatelessWidget {
  const _ThemeArtworkFallback({required this.preset});

  final AkashaThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final preview = AkashaPalette.fromPreset(preset);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [preview.sidebar, preview.surface, preview.accentSoft],
        ),
      ),
      child: Center(
        child: Icon(Icons.auto_awesome, color: preview.accent, size: 34),
      ),
    );
  }
}

class _ThemeBadge extends StatelessWidget {
  const _ThemeBadge({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(
  AkashaPalette palette,
  ThemeAccessState access,
  ThemeCatalogEntry catalog,
) {
  if (access.grantsAccess) return palette.accent;
  if (access == ThemeAccessState.checking) return palette.info;
  if (catalog.offerState == ThemeOfferState.planned) return palette.warning;
  if (catalog.offerState == ThemeOfferState.paused) return palette.textMuted;
  return palette.warning;
}

String _themeStatusLabel(
  AppLocalizations? l10n,
  ThemeCatalogEntry catalog,
  ThemeAccessState access,
) {
  if (access == ThemeAccessState.free) {
    return l10n?.themeStatusIncluded ?? '무료 포함';
  }
  if (access == ThemeAccessState.owned) {
    return l10n?.themeStatusOwned ?? '보유 중';
  }
  if (access == ThemeAccessState.checking) {
    return l10n?.themeStatusChecking ?? '소유권 확인 중';
  }
  if (catalog.offerState == ThemeOfferState.planned) {
    return l10n?.themeStatusPlannedPremium ?? '유료 · 출시 예정';
  }
  if (catalog.offerState == ThemeOfferState.paused) {
    return l10n?.themeStatusOfferPaused ?? '일시 판매 중지';
  }
  if (catalog.hasActiveOffer && access == ThemeAccessState.locked) {
    return l10n?.themeStatusPurchaseRequired ?? '구매 필요';
  }
  return l10n?.themeStatusUnavailable ?? '소유권 확인 불가';
}

String? _themePriceLabel(AppLocalizations? l10n, ThemeCatalogEntry catalog) {
  final astra = catalog.astraCost;
  final echo = catalog.echoCost;
  if (astra != null && echo != null) {
    return l10n?.themePriceChooseOne(astra, echo) ??
        '$astra Astra 또는 $echo Echo';
  }
  if (astra != null) return '$astra Astra';
  if (echo != null) return '$echo Echo';
  return null;
}

String _localizedThemeName(
  AppLocalizations? l10n,
  AkashaThemeDefinition definition,
) {
  final catalog = definition.catalog;
  return switch (catalog.displayNameL10nKey) {
    'themeClassicDarkName' =>
      l10n?.themeClassicDarkName ?? catalog.fallbackDisplayName,
    'themeMidnightBlueName' =>
      l10n?.themeMidnightBlueName ?? catalog.fallbackDisplayName,
    'themeSakuraName' => l10n?.themeSakuraName ?? catalog.fallbackDisplayName,
    'themeAmethystName' =>
      l10n?.themeAmethystName ?? catalog.fallbackDisplayName,
    'themeNocturneName' =>
      l10n?.themeNocturneName ?? catalog.fallbackDisplayName,
    _ => catalog.fallbackDisplayName,
  };
}
