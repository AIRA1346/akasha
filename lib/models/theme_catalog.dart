import 'package:flutter/foundation.dart';

enum ThemeAccessType { bundled, premium }

/// Whether a catalog entry currently has a real product offer.
///
/// This is deliberately separate from [ThemeAccessState]. A premium theme may
/// be discoverable while its offer is still planned, and an owned theme remains
/// usable even if a later offer is paused.
enum ThemeOfferState { included, planned, purchasable, paused }

/// Product-facing metadata for a visual theme preset.
///
/// Prices and entitlement identifiers remain nullable until production catalog
/// values are approved. Visual rendering data must not be added here.
@immutable
class ThemeCatalogEntry {
  final String presetId;
  final String displayNameL10nKey;
  final String fallbackDisplayName;
  final ThemeAccessType accessType;
  final ThemeOfferState offerState;
  final int? astraCost;
  final int? echoCost;
  final String? commerceProductId;
  final String? entitlementKey;

  const ThemeCatalogEntry({
    required this.presetId,
    required this.displayNameL10nKey,
    required this.fallbackDisplayName,
    required this.accessType,
    required this.offerState,
    this.astraCost,
    this.echoCost,
    this.commerceProductId,
    this.entitlementKey,
  });

  bool get isBundled => accessType == ThemeAccessType.bundled;
  bool get isPremium => accessType == ThemeAccessType.premium;
  bool get hasActiveOffer => offerState == ThemeOfferState.purchasable;
  bool get hasApprovedPrice => astraCost != null || echoCost != null;
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
