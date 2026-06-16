// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get browseLoadingCatalog => '글로벌 작품 사전 불러오는 중…';

  @override
  String get browseNoResults => '조건에 맞는 작품이 없습니다.';

  @override
  String browseCatalogIndexed(int loaded, int total) {
    return '글로벌 사전 $loaded / $total 작품 색인 로드됨';
  }

  @override
  String browseLoadMore(int count) {
    return '더 불러오기 (+$count)';
  }

  @override
  String get settingsDisplayLanguage => '표시 언어';

  @override
  String get localeKo => '한국어';

  @override
  String get localeEn => 'English';

  @override
  String get appBarToggleSidebar => '사이드바 토글 (Tab)';

  @override
  String get appBarLibraryTheme => '서재 테마';

  @override
  String get appBarSearch => '검색';

  @override
  String get appBarTimelineCapture => '타임라인 기록';

  @override
  String get appBarCatalogInbox => '카탈로그 제안함';

  @override
  String get appBarClipboardImport => 'AI 마크다운 가져오기';

  @override
  String get appBarSyncRegistry => '글로벌 작품 사전 동기화 (길게 눌러 설정)';

  @override
  String get appBarPromptTemplates => 'AI 프롬프트 템플릿 복사';

  @override
  String get appBarClearRegistryCache => '글로벌 사전 JSON 캐시 삭제 (이미지 파일 아님)';

  @override
  String get appBarVaultSettings => '로컬 폴더(Vault) 설정';
}
