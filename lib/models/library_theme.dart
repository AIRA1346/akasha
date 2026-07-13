import 'package:flutter/material.dart';

import '../theme/akasha_theme_preset.dart';
import 'theme_catalog.dart';

/// Compatibility adapter for code written before the app-wide theme model.
///
/// New theme rendering code should use [AkashaThemePreset]. Product access and
/// display metadata belong to [ThemeCatalog]. This adapter remains during the
/// stored-ID migration so existing Home surfaces do not need a flag-day
/// rewrite.
@Deprecated('Use AkashaThemePreset and ThemeCatalog.')
class LibraryTheme {
  final AkashaThemePreset preset;

  const LibraryTheme._(this.preset);

  String get id => preset.id;
  Color get backgroundColor => preset.backgroundColor;
  Color get accentColor => preset.accentColor;

  String get name => switch (id) {
    'classicDark' => 'Classic Dark',
    'midnightBlue' => 'Midnight Blue',
    'sakura' => 'Sakura',
    'amethyst' => 'Amethyst',
    'nocturne' => 'Nocturne',
    _ => id,
  };

  static const LibraryTheme classic = LibraryTheme._(
    AkashaThemePreset.classicDark,
  );
  static const LibraryTheme midnight = LibraryTheme._(
    AkashaThemePreset.midnightBlue,
  );
  static const LibraryTheme sakura = LibraryTheme._(AkashaThemePreset.sakura);
  static const LibraryTheme amethyst = LibraryTheme._(
    AkashaThemePreset.amethyst,
  );
  static const LibraryTheme nocturne = LibraryTheme._(
    AkashaThemePreset.nocturne,
  );

  static const List<LibraryTheme> all = [
    classic,
    midnight,
    sakura,
    amethyst,
    nocturne,
  ];

  static LibraryTheme fromPreset(AkashaThemePreset preset) {
    for (final theme in all) {
      if (theme.id == preset.id) return theme;
    }
    return classic;
  }

  /// Accepts canonical IDs and the known persisted legacy aliases.
  static LibraryTheme? byId(String id) {
    final canonical = ThemeCatalog.canonicalPresetId(id);
    if (canonical == null) return null;
    for (final theme in all) {
      if (theme.id == canonical) return theme;
    }
    return null;
  }
}
