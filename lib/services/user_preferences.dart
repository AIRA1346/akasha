import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 유저 표시 설정 (스팀 persona name 연동 대비)
class UserPreferences {
  static const String displayNameKey = 'akasha_display_name';
  static const String autoArchiveRegistryKey = 'akasha_auto_archive_registry';
  static const String vaultWorksLayoutKey = 'akasha_vault_use_works_layout';
  static const String uiScaleKey = 'akasha_ui_scale';
  static const double defaultUiScale = 1.0;
  static const double minUiScale = 0.9;
  static const double maxUiScale = 1.25;

  static final ValueNotifier<double> uiScaleListenable = ValueNotifier(
    defaultUiScale,
  );

  static double normalizeUiScale(double scale) {
    if (scale.isNaN || scale.isInfinite) return defaultUiScale;
    return scale.clamp(minUiScale, maxUiScale).toDouble();
  }

  static Future<double> loadInitialUiScale() async {
    final prefs = await SharedPreferences.getInstance();
    final scale = normalizeUiScale(
      prefs.getDouble(uiScaleKey) ?? defaultUiScale,
    );
    uiScaleListenable.value = scale;
    return scale;
  }

  static Future<void> setUiScale(double scale) async {
    final normalized = normalizeUiScale(scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(uiScaleKey, normalized);
    uiScaleListenable.value = normalized;
  }

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

  /// ID가 없는 title 기반 Work 경로의 `works/` 레이아웃 호환 preference.
  ///
  /// preference가 없으면 `true`가 기본값이다. ID 기반 Work는 이 값과 무관하게
  /// `works/{category}/{workId}.md`에 저장되며, 기존 `filePath`는 강제 이동하지 않는다.
  /// TODO(remove): L1 — docs/active/LEGACY_REMOVAL_POLICY.md §2.2
  static Future<bool> isVaultWorksLayoutEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vaultWorksLayoutKey) ?? true;
  }

  static Future<void> setVaultWorksLayoutEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vaultWorksLayoutKey, enabled);
  }
}
