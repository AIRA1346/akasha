// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get browseLoadingCatalog => 'Loading global works catalog…';

  @override
  String get browseNoResults => 'No works match your filters.';

  @override
  String browseCatalogIndexed(int loaded, int total) {
    return '$loaded / $total works indexed';
  }

  @override
  String browseLoadMore(int count) {
    return 'Load more (+$count)';
  }

  @override
  String get settingsDisplayLanguage => 'Display language';

  @override
  String get localeKo => 'Korean';

  @override
  String get localeEn => 'English';

  @override
  String get appBarToggleSidebar => 'Toggle sidebar (Tab)';

  @override
  String get appBarLibraryTheme => 'Library theme';

  @override
  String get appBarSearch => 'Search';

  @override
  String get appBarTimelineCapture => 'Timeline note';

  @override
  String get appBarCatalogInbox => 'Catalog suggestions inbox';

  @override
  String get appBarClipboardImport => 'Import AI markdown';

  @override
  String get appBarSyncRegistry =>
      'Sync global works catalog (long-press for settings)';

  @override
  String get appBarPromptTemplates => 'Copy AI prompt templates';

  @override
  String get appBarClearRegistryCache =>
      'Clear catalog JSON cache (not poster images)';

  @override
  String get appBarVaultSettings => 'Local vault settings';
}
