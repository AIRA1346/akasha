import 'package:flutter/material.dart';
import 'package:akasha_commerce_domain/akasha_commerce_domain.dart';

import '../models/theme_catalog.dart';
import 'akasha_theme_preset.dart';

/// One registration record for an official visual preset and its product
/// metadata. Rendering and commerce remain separate models, while this registry
/// guarantees that they share one canonical ID and one source list.
@immutable
class AkashaThemeDefinition {
  final AkashaThemePreset preset;
  final ThemeCatalogEntry catalog;

  const AkashaThemeDefinition({required this.preset, required this.catalog});

  String get id => preset.id;
}

abstract final class AkashaThemeRegistry {
  static const defaultThemeId = 'classicDark';

  static const classicDarkPreset = AkashaThemePreset(
    id: defaultThemeId,
    backgroundColor: Color(0xFF13131D),
    accentColor: Color(0xFF6C63FF),
    assets: AkashaThemeAssets(
      backdropAssetPath: 'assets/themes/classicDark/backdrop.png',
      heroAssetPath: 'assets/themes/classicDark/hero.png',
    ),
    effects: AkashaThemeEffects.neutral,
  );

  static const classicDarkCatalog = ThemeCatalogEntry(
    presetId: defaultThemeId,
    displayNameL10nKey: 'themeClassicDarkName',
    fallbackDisplayName: 'Classic Dark',
    accessType: ThemeAccessType.bundled,
    offerState: ThemeOfferState.included,
  );

  static const classicDark = AkashaThemeDefinition(
    preset: classicDarkPreset,
    catalog: classicDarkCatalog,
  );

  static const midnightBluePreset = AkashaThemePreset(
    id: 'midnightBlue',
    backgroundColor: Color(0xFF0D1B2A),
    accentColor: Color(0xFF64B5F6),
    assets: AkashaThemeAssets(
      backdropAssetPath: 'assets/themes/midnightBlue/backdrop.png',
      heroAssetPath: 'assets/themes/midnightBlue/hero.png',
    ),
    effects: AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0.16,
        scrimOpacity: 0.64,
        textureOpacity: 0.64,
        ambientOpacity: 0,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0.16, shadowIntensity: 0.48),
    ),
  );

  static const midnightBlueCatalog = ThemeCatalogEntry(
    presetId: 'midnightBlue',
    displayNameL10nKey: 'themeMidnightBlueName',
    fallbackDisplayName: 'Midnight Blue',
    accessType: ThemeAccessType.bundled,
    offerState: ThemeOfferState.included,
  );

  static const midnightBlue = AkashaThemeDefinition(
    preset: midnightBluePreset,
    catalog: midnightBlueCatalog,
  );

  static const sakuraPreset = AkashaThemePreset(
    id: 'sakura',
    backgroundColor: Color(0xFF2A1A22),
    accentColor: Color(0xFFF48FB1),
    assets: AkashaThemeAssets(
      backdropAssetPath: 'assets/themes/sakura/backdrop.png',
      heroAssetPath: 'assets/themes/sakura/hero.png',
    ),
    effects: AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0.18,
        scrimOpacity: 0.62,
        textureOpacity: 0.62,
        ambientOpacity: 0,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0.18, shadowIntensity: 0.48),
    ),
  );

  static const sakuraCatalog = ThemeCatalogEntry(
    presetId: 'sakura',
    displayNameL10nKey: 'themeSakuraName',
    fallbackDisplayName: 'Sakura',
    accessType: ThemeAccessType.premium,
    offerState: ThemeOfferState.planned,
    astraCost: CommerceCatalog.launchThemeAstraPrice,
    echoCost: CommerceCatalog.launchThemeEchoPrice,
    commerceProductId: CommerceCatalog.sakuraThemeProductId,
    entitlementKey: CommerceCatalog.sakuraThemeEntitlementKey,
  );

  static const sakura = AkashaThemeDefinition(
    preset: sakuraPreset,
    catalog: sakuraCatalog,
  );

  static const amethystPreset = AkashaThemePreset(
    id: 'amethyst',
    backgroundColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFB39DDB),
    assets: AkashaThemeAssets(
      backdropAssetPath: 'assets/themes/amethyst/backdrop.png',
      heroAssetPath: 'assets/themes/amethyst/hero.png',
    ),
    effects: AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0.22,
        scrimOpacity: 0.64,
        textureOpacity: 0.64,
        ambientOpacity: 0,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0.22, shadowIntensity: 0.52),
    ),
  );

  static const amethystCatalog = ThemeCatalogEntry(
    presetId: 'amethyst',
    displayNameL10nKey: 'themeAmethystName',
    fallbackDisplayName: 'Amethyst',
    accessType: ThemeAccessType.premium,
    offerState: ThemeOfferState.planned,
    astraCost: CommerceCatalog.launchThemeAstraPrice,
    echoCost: CommerceCatalog.launchThemeEchoPrice,
    commerceProductId: CommerceCatalog.amethystThemeProductId,
    entitlementKey: CommerceCatalog.amethystThemeEntitlementKey,
  );

  static const amethyst = AkashaThemeDefinition(
    preset: amethystPreset,
    catalog: amethystCatalog,
  );

  static const nocturnePreset = AkashaThemePreset(
    id: 'nocturne',
    backgroundColor: Color(0xFF090B0F),
    accentColor: Color(0xFF93A4BD),
    assets: AkashaThemeAssets(
      backdropAssetPath: 'assets/themes/nocturne/backdrop.png',
      heroAssetPath: 'assets/themes/nocturne/hero.png',
    ),
    effects: AkashaThemeEffects(
      backdrop: AkashaBackdropEffects(
        glowIntensity: 0.10,
        scrimOpacity: 0.68,
        textureOpacity: 0.68,
        ambientOpacity: 0,
      ),
      hero: AkashaHeroEffects(glowIntensity: 0.10, shadowIntensity: 0.55),
    ),
  );

  static const nocturneCatalog = ThemeCatalogEntry(
    presetId: 'nocturne',
    displayNameL10nKey: 'themeNocturneName',
    fallbackDisplayName: 'Nocturne',
    accessType: ThemeAccessType.premium,
    offerState: ThemeOfferState.planned,
    astraCost: CommerceCatalog.launchThemeAstraPrice,
    echoCost: CommerceCatalog.launchThemeEchoPrice,
    commerceProductId: CommerceCatalog.nocturneThemeProductId,
    entitlementKey: CommerceCatalog.nocturneThemeEntitlementKey,
  );

  static const nocturne = AkashaThemeDefinition(
    preset: nocturnePreset,
    catalog: nocturneCatalog,
  );

  static const List<AkashaThemeDefinition> all = [
    classicDark,
    midnightBlue,
    sakura,
    amethyst,
    nocturne,
  ];

  static const Map<String, String> persistedAliases = {
    'classic': 'classicDark',
    'midnight': 'midnightBlue',
    'obsidian': 'amethyst',
  };

  static final Map<String, AkashaThemeDefinition> _byId = {
    for (final definition in all) definition.id: definition,
  };

  static final List<AkashaThemePreset> presets = List.unmodifiable(
    all.map((definition) => definition.preset),
  );

  static final List<ThemeCatalogEntry> catalogEntries = List.unmodifiable(
    all.map((definition) => definition.catalog),
  );

  static AkashaThemeDefinition? byId(String id) => _byId[id];

  static AkashaThemePreset? presetById(String id) => byId(id)?.preset;

  static ThemeCatalogEntry? catalogById(String id) => byId(id)?.catalog;

  /// Converts known persisted aliases and accepts every registered canonical
  /// ID automatically. Unknown values remain unknown so preferences can retain
  /// them without inventing meaning.
  static String? canonicalId(String persistedId) {
    final aliased = persistedAliases[persistedId];
    if (aliased != null) return aliased;
    return _byId.containsKey(persistedId) ? persistedId : null;
  }
}
