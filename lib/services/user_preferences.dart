import 'package:shared_preferences/shared_preferences.dart';

/// 유저 표시 설정 (스팀 persona name 연동 대비)
class UserPreferences {
  static const String displayNameKey = 'akasha_display_name';
  static const String defaultDisplayName = '사용자';

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(displayNameKey)?.trim();
    if (name == null || name.isEmpty) return defaultDisplayName;
    return name;
  }

  static Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(displayNameKey);
    } else {
      await prefs.setString(displayNameKey, trimmed);
    }
  }
}
