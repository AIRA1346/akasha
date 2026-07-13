import 'package:flutter/foundation.dart';

enum ThemeAccessType { bundled, premium }

/// Product-facing metadata for a visual theme preset.
///
/// Prices and entitlement identifiers remain nullable until production catalog
/// values are approved. Visual rendering data must not be added here.
@immutable
class ThemeCatalogEntry {
  final String presetId;
  final String displayNameL10nKey;
  final ThemeAccessType accessType;
  final int? astraCost;
  final int? echoCost;
  final String? entitlementItemDefId;

  const ThemeCatalogEntry({
    required this.presetId,
    required this.displayNameL10nKey,
    required this.accessType,
    this.astraCost,
    this.echoCost,
    this.entitlementItemDefId,
  });

  bool get isBundled => accessType == ThemeAccessType.bundled;
  bool get isPremium => accessType == ThemeAccessType.premium;
}

/// Canonical product catalog for the first five AKASHA themes.
abstract final class ThemeCatalog {
  static const classicDark = ThemeCatalogEntry(
    presetId: 'classicDark',
    displayNameL10nKey: 'themeClassicDarkName',
    accessType: ThemeAccessType.bundled,
  );

  static const midnightBlue = ThemeCatalogEntry(
    presetId: 'midnightBlue',
    displayNameL10nKey: 'themeMidnightBlueName',
    accessType: ThemeAccessType.bundled,
  );

  static const sakura = ThemeCatalogEntry(
    presetId: 'sakura',
    displayNameL10nKey: 'themeSakuraName',
    accessType: ThemeAccessType.premium,
  );

  static const amethyst = ThemeCatalogEntry(
    presetId: 'amethyst',
    displayNameL10nKey: 'themeAmethystName',
    accessType: ThemeAccessType.premium,
  );

  static const nocturne = ThemeCatalogEntry(
    presetId: 'nocturne',
    displayNameL10nKey: 'themeNocturneName',
    accessType: ThemeAccessType.premium,
  );

  static const List<ThemeCatalogEntry> all = [
    classicDark,
    midnightBlue,
    sakura,
    amethyst,
    nocturne,
  ];

  static ThemeCatalogEntry? byPresetId(String presetId) {
    for (final entry in all) {
      if (entry.presetId == presetId) return entry;
    }
    return null;
  }

  /// Converts only known persisted aliases. Unknown values stay unknown so the
  /// preference layer can preserve the raw value without inventing meaning.
  static String? canonicalPresetId(String persistedId) {
    return switch (persistedId) {
      'classic' => classicDark.presetId,
      'midnight' => midnightBlue.presetId,
      'obsidian' => amethyst.presetId,
      'classicDark' ||
      'midnightBlue' ||
      'sakura' ||
      'amethyst' ||
      'nocturne' => persistedId,
      _ => null,
    };
  }
}

enum ThemeAccessState { free, owned, locked, checking, unavailable }

extension ThemeAccessStateAccess on ThemeAccessState {
  bool get grantsAccess =>
      this == ThemeAccessState.free || this == ThemeAccessState.owned;
}

/// Preferred and effective theme IDs are intentionally separate.
///
/// [preferredThemeId] is retained even when access or a visual preset is
/// temporarily unavailable. Only [effectiveThemeId] falls back.
@immutable
class ThemeSelection {
  final String preferredThemeId;
  final String effectiveThemeId;
  final ThemeAccessState accessState;

  const ThemeSelection({
    required this.preferredThemeId,
    required this.effectiveThemeId,
    required this.accessState,
  });

  bool get didFallback => preferredThemeId != effectiveThemeId;
}

/// Pure access and selection rules, independent of a commerce provider.
abstract final class ThemeAccessResolver {
  static ThemeAccessState resolve({
    required ThemeCatalogEntry entry,
    required bool authorityAvailable,
    required bool isChecking,
    required bool? isOwned,
  }) {
    if (entry.isBundled) return ThemeAccessState.free;
    if (!authorityAvailable) return ThemeAccessState.unavailable;
    if (isChecking) return ThemeAccessState.checking;
    if (isOwned == null) return ThemeAccessState.unavailable;
    return isOwned ? ThemeAccessState.owned : ThemeAccessState.locked;
  }

  static ThemeSelection select({
    required String preferredThemeId,
    required Set<String> availablePresetIds,
    required Map<String, ThemeAccessState> accessByPresetId,
    String fallbackThemeId = 'classicDark',
  }) {
    final accessState =
        accessByPresetId[preferredThemeId] ?? ThemeAccessState.unavailable;
    final canApply =
        availablePresetIds.contains(preferredThemeId) &&
        accessState.grantsAccess;

    return ThemeSelection(
      preferredThemeId: preferredThemeId,
      effectiveThemeId: canApply ? preferredThemeId : fallbackThemeId,
      accessState: accessState,
    );
  }
}
