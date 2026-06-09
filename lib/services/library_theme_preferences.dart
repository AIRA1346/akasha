import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_theme.dart';

/// 나만의 서재 비주얼 테마 영속화.
class LibraryThemePreferences {
  LibraryThemePreferences._();

  static const _prefsKey = 'akasha_library_theme_id';

  static Future<LibraryTheme> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKey);
    return LibraryTheme.byId(savedId ?? '') ?? LibraryTheme.classic;
  }

  static Future<void> save(LibraryTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, theme.id);
  }
}
