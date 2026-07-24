import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user-controlled visibility of the right Inspector rail.
abstract final class HomeInspectorPreferences {
  static const _prefKey = 'akasha_inspector_open';

  static Future<bool> loadOpen({bool defaultOpen = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? defaultOpen;
    } catch (_) {
      return defaultOpen;
    }
  }

  static Future<void> saveOpen(bool open) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, open);
    } catch (_) {}
  }
}
