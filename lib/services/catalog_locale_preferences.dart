import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

import '../config/catalog_locale.dart';

/// 카탈로그·UI 표시 언어 영속화 (E3-A2).
class CatalogLocalePreferences {
  CatalogLocalePreferences._();

  static const String key = 'akasha_catalog_locale';

  /// 저장값 → 없으면 OS 로케일 → `ko`/`en`만 UI 설정 대상.
  static Future<CatalogLocale> loadInitial() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(key);
      if (saved != null && saved.isNotEmpty) {
        return _uiLocale(CatalogLocale.fromLanguageTag(saved));
      }
    } catch (_) {}
    return _uiLocale(CatalogLocale.fromLanguageTag(Platform.localeName));
  }

  static Future<void> save(CatalogLocale locale) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, _uiLocale(locale).tag);
  }

  /// 설정 UI에서 선택 가능한 로케일 (v1.1: ko/en).
  static CatalogLocale _uiLocale(CatalogLocale locale) =>
      locale == CatalogLocale.en ? CatalogLocale.en : CatalogLocale.ko;
}
