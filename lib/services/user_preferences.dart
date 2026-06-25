import 'package:shared_preferences/shared_preferences.dart';

/// 유저 표시 설정 (스팀 persona name 연동 대비)
class UserPreferences {
  static const String displayNameKey = 'akasha_display_name';
  static const String autoArchiveRegistryKey = 'akasha_auto_archive_registry';
  static const String vaultWorksLayoutKey = 'akasha_vault_use_works_layout';
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

  /// Wave 2 — 신규 work journal을 `{vault}/works/{subtype}/`에 저장.
  /// 기본값 false: 기존 볼트 호환. TODO(remove): L1 — docs/draft/LEGACY_REMOVAL_POLICY.md §2.2
  static Future<bool> isVaultWorksLayoutEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vaultWorksLayoutKey) ?? false;
  }

  static Future<void> setVaultWorksLayoutEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vaultWorksLayoutKey, enabled);
  }
}
