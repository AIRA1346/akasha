/// 글로벌 카탈로그·UI 표시용 로케일 (Flutter i18n 도입 전 브리지)
enum CatalogLocale {
  ko,
  en,
  ja,
  zh;

  /// BCP-47 태그 (`ko`, `en`, `ja`, `zh`)
  String get tag => name;

  /// `Platform.localeName` / `Locale.toLanguageTag()` 등에서 추론
  static CatalogLocale fromLanguageTag(String? tag) {
    final normalized = (tag ?? '').toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('ko')) return CatalogLocale.ko;
    if (normalized.startsWith('ja')) return CatalogLocale.ja;
    if (normalized.startsWith('zh')) return CatalogLocale.zh;
    if (normalized.startsWith('en')) return CatalogLocale.en;
    return CatalogLocale.ko;
  }

  /// 카탈로그 제목 fallback 우선순위 (표시용)
  List<String> get titleFallbackTags {
    switch (this) {
      case CatalogLocale.ko:
        return const ['ko', 'en', 'ja', 'romaji', 'native', 'zh'];
      case CatalogLocale.en:
        return const ['en', 'romaji', 'ja', 'native', 'ko', 'zh'];
      case CatalogLocale.ja:
        return const ['ja', 'native', 'romaji', 'en', 'ko', 'zh'];
      case CatalogLocale.zh:
        return const ['zh', 'native', 'en', 'romaji', 'ja', 'ko'];
    }
  }
}

/// 앱 전역 카탈로그 로케일 (v1: ko 고정, v1.1+ 에서 설정·시스템 연동)
class CatalogLocaleScope {
  CatalogLocaleScope._();

  static CatalogLocale _current = CatalogLocale.ko;

  static CatalogLocale get current => _current;

  static void setCurrent(CatalogLocale locale) {
    _current = locale;
  }

  static void setFromLanguageTag(String? tag) {
    _current = CatalogLocale.fromLanguageTag(tag);
  }
}
