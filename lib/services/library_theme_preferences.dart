import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_theme.dart';
import '../models/theme_catalog.dart';

/// Stored theme preference compatibility and canonical-ID migration.
class LibraryThemePreferences {
  LibraryThemePreferences._();

  static const _legacyPrefsKey = 'akasha_library_theme_id';
  static const _preferredPrefsKey = 'akasha_preferred_theme_id';

  /// Loads the user's preference without collapsing an unknown value.
  ///
  /// Known legacy aliases are migrated to the canonical key. Unknown values
  /// stay stored so a temporarily missing preset can become available again.
  static Future<String> loadPreferredId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_preferredPrefsKey) ??
        prefs.getString(_legacyPrefsKey) ??
        ThemeCatalog.classicDark.presetId;
    final canonical = ThemeCatalog.canonicalPresetId(raw);
    if (canonical == null) {
      if (prefs.getString(_preferredPrefsKey) == null) {
        await prefs.setString(_preferredPrefsKey, raw);
      }
      return raw;
    }
    if (prefs.getString(_preferredPrefsKey) != canonical) {
      await prefs.setString(_preferredPrefsKey, canonical);
    }
    return canonical;
  }

  static Future<void> savePreferredId(String presetId) async {
    final canonical = ThemeCatalog.canonicalPresetId(presetId);
    if (canonical == null) {
      throw ArgumentError.value(presetId, 'presetId', 'Unknown theme preset');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredPrefsKey, canonical);
  }

  /// Legacy object API retained for the Home migration window.
  static Future<LibraryTheme> load() async {
    final preferredId = await loadPreferredId();
    return LibraryTheme.byId(preferredId) ?? LibraryTheme.classic;
  }

  static Future<void> save(LibraryTheme theme) async {
    await savePreferredId(theme.id);
  }
}
