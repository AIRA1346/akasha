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
}
