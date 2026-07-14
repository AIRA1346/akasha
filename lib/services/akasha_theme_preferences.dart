import 'package:shared_preferences/shared_preferences.dart';

import '../theme/akasha_theme_registry.dart';

/// Stored app-theme preference compatibility and canonical-ID migration.
abstract final class AkashaThemePreferences {
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
        AkashaThemeRegistry.defaultThemeId;
    final canonical = AkashaThemeRegistry.canonicalId(raw);
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
    final canonical = AkashaThemeRegistry.canonicalId(presetId);
    if (canonical == null) {
      throw ArgumentError.value(presetId, 'presetId', 'Unknown theme preset');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredPrefsKey, canonical);
  }
}
