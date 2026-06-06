import 'package:shared_preferences/shared_preferences.dart';

/// 유저 표시 설정 (스팀 persona name 연동 대비)
class UserPreferences {
  static const String displayNameKey = 'akasha_display_name';
  static const String autoArchiveRegistryKey = 'akasha_auto_archive_registry';
  static const String defaultDisplayName = '사용자';

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(displayNameKey)?.trim();
    if (name == null || name.isEmpty) return defaultDisplayName;
    return name;
  }

  static Future<bool> isAutoArchiveRegistryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(autoArchiveRegistryKey) ?? false;
  }

  static Future<void> setAutoArchiveRegistryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoArchiveRegistryKey, enabled);
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
