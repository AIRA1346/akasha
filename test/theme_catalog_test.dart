import 'package:akasha/models/theme_catalog.dart';
import 'package:akasha/theme/akasha_theme_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official preset and catalog IDs match and are unique', () {
    final presetIds = AkashaThemePreset.all.map((e) => e.id).toSet();
    final catalogIds = ThemeCatalog.all.map((e) => e.presetId).toSet();

    expect(presetIds, hasLength(5));
    expect(catalogIds, hasLength(5));
    expect(presetIds, catalogIds);
    expect(ThemeCatalog.classicDark.isBundled, isTrue);
    expect(ThemeCatalog.midnightBlue.isBundled, isTrue);
    expect(ThemeCatalog.sakura.isPremium, isTrue);
    expect(ThemeCatalog.amethyst.isPremium, isTrue);
    expect(ThemeCatalog.nocturne.isPremium, isTrue);
  });

  test('legacy IDs normalize without inventing an Astral alias', () {
    expect(ThemeCatalog.canonicalPresetId('classic'), 'classicDark');
    expect(ThemeCatalog.canonicalPresetId('midnight'), 'midnightBlue');
    expect(ThemeCatalog.canonicalPresetId('obsidian'), 'amethyst');
    expect(ThemeCatalog.canonicalPresetId('sakura'), 'sakura');
    expect(ThemeCatalog.canonicalPresetId('astral'), isNull);
    expect(ThemeCatalog.canonicalPresetId('unknown'), isNull);
  });

  test('access resolver distinguishes all provider states', () {
    expect(
      ThemeAccessResolver.resolve(
        entry: ThemeCatalog.classicDark,
        authorityAvailable: false,
        isChecking: false,
        isOwned: null,
      ),
      ThemeAccessState.free,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: ThemeCatalog.sakura,
        authorityAvailable: false,
        isChecking: false,
        isOwned: null,
      ),
      ThemeAccessState.unavailable,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: ThemeCatalog.sakura,
        authorityAvailable: true,
        isChecking: true,
        isOwned: null,
      ),
      ThemeAccessState.checking,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: ThemeCatalog.sakura,
        authorityAvailable: true,
        isChecking: false,
        isOwned: false,
      ),
      ThemeAccessState.locked,
    );
    expect(
      ThemeAccessResolver.resolve(
        entry: ThemeCatalog.sakura,
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
      availablePresetIds: AkashaThemePreset.all.map((e) => e.id).toSet(),
      accessByPresetId: const {'sakura': ThemeAccessState.unavailable},
    );

    expect(selection.preferredThemeId, 'sakura');
    expect(selection.effectiveThemeId, 'classicDark');
    expect(selection.didFallback, isTrue);
  });
}
