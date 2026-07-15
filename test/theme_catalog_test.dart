import 'package:akasha/theme/akasha_theme_registry.dart';
import 'package:akasha/models/theme_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'registry keeps preset and product metadata in one valid definition',
    () {
      final definitions = AkashaThemeRegistry.all;
      final ids = definitions.map((definition) => definition.id).toSet();

      expect(definitions, hasLength(5));
      expect(ids, hasLength(definitions.length));
      for (final definition in definitions) {
        expect(definition.catalog.presetId, definition.preset.id);
        expect(definition.catalog.displayNameL10nKey, isNotEmpty);
        expect(definition.catalog.fallbackDisplayName, isNotEmpty);
        expect(AkashaThemeRegistry.byId(definition.id), same(definition));
        expect(
          AkashaThemeRegistry.presetById(definition.id),
          same(definition.preset),
        );
        expect(
          AkashaThemeRegistry.catalogById(definition.id),
          same(definition.catalog),
        );
        expect(AkashaThemeRegistry.canonicalId(definition.id), definition.id);
      }

      expect(AkashaThemeRegistry.presets, hasLength(definitions.length));
      expect(AkashaThemeRegistry.catalogEntries, hasLength(definitions.length));
      expect(AkashaThemeRegistry.classicDarkCatalog.isBundled, isTrue);
      expect(AkashaThemeRegistry.midnightBlueCatalog.isBundled, isTrue);
      expect(
        AkashaThemeRegistry.classicDarkCatalog.offerState,
        ThemeOfferState.included,
      );
      expect(
        AkashaThemeRegistry.midnightBlueCatalog.offerState,
        ThemeOfferState.included,
      );
      expect(AkashaThemeRegistry.sakuraCatalog.isPremium, isTrue);
      expect(AkashaThemeRegistry.amethystCatalog.isPremium, isTrue);
      expect(AkashaThemeRegistry.nocturneCatalog.isPremium, isTrue);
      for (final catalog in [
        AkashaThemeRegistry.sakuraCatalog,
        AkashaThemeRegistry.amethystCatalog,
        AkashaThemeRegistry.nocturneCatalog,
      ]) {
        expect(catalog.offerState, ThemeOfferState.planned);
        expect(catalog.hasActiveOffer, isFalse);
        expect(catalog.astraCost, 500);
        expect(catalog.echoCost, 500);
        expect(catalog.hasApprovedPrice, isTrue);
        expect(catalog.commerceProductId, isNotEmpty);
        expect(catalog.entitlementKey, startsWith('theme:'));
      }
    },
  );

  test('legacy IDs normalize without inventing an Astral alias', () {
    for (final alias in AkashaThemeRegistry.persistedAliases.entries) {
      expect(AkashaThemeRegistry.byId(alias.value), isNotNull);
      expect(AkashaThemeRegistry.canonicalId(alias.key), alias.value);
    }
    expect(AkashaThemeRegistry.canonicalId('astral'), isNull);
    expect(AkashaThemeRegistry.canonicalId('unknown'), isNull);
  });

  test('provider entitlements map to premium preset IDs only', () {
    expect(
      AkashaThemeRegistry.presetIdsForEntitlements({
        'theme:sakura',
        'theme:nocturne',
        'future:unknown',
      }),
      {'sakura', 'nocturne'},
    );
    expect(AkashaThemeRegistry.presetIdsForEntitlements(const {}), isEmpty);
  });

  test('access resolver distinguishes all provider states', () {
    expect(
      ThemeAccessResolver.resolve(
        entry: AkashaThemeRegistry.classicDarkCatalog,
        authorityAvailable: false,
        isChecking: false,
        isOwned: null,
      ),
      ThemeAccessState.free,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: AkashaThemeRegistry.sakuraCatalog,
        authorityAvailable: false,
        isChecking: false,
        isOwned: null,
      ),
      ThemeAccessState.unavailable,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: AkashaThemeRegistry.sakuraCatalog,
        authorityAvailable: true,
        isChecking: true,
        isOwned: null,
      ),
      ThemeAccessState.checking,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: AkashaThemeRegistry.sakuraCatalog,
        authorityAvailable: true,
        isChecking: false,
        isOwned: false,
      ),
      ThemeAccessState.locked,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: AkashaThemeRegistry.sakuraCatalog,
        authorityAvailable: true,
        isChecking: false,
        isOwned: true,
      ),
      ThemeAccessState.owned,
    );
  });

  test('selection preserves preferred ID while effective falls back', () {
    final selection = ThemeAccessResolver.select(
      preferredThemeId: 'sakura',
      availablePresetIds: AkashaThemeRegistry.presets.map((e) => e.id).toSet(),
      accessByPresetId: const {'sakura': ThemeAccessState.unavailable},
    );

    expect(selection.preferredThemeId, 'sakura');
    expect(selection.effectiveThemeId, 'classicDark');
    expect(selection.didFallback, isTrue);
  });
}
