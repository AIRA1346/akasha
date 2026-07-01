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
  String get appPreferencesTitle => 'Preferences';

  @override
  String get appPreferencesDisplayScale => 'Display scale';

  @override
  String get appPreferencesResetScale => 'Reset to 100%';

  @override
  String get appPreferencesScaleHelp =>
      'Adjust text and major control size across the app.';

  @override
  String get appPreferencesThemeTitle => 'App theme';

  @override
  String get appPreferencesThemeSubtitle => 'Change the color palette.';

  @override
  String get appPreferencesVaultTitle => 'Vault settings';

  @override
  String get appPreferencesVaultSubtitle =>
      'Manage the storage folder, backups, and trash.';

  @override
  String get appPreferencesQuit => 'Quit';

  @override
  String get appPreferencesClose => 'Close';

  @override
  String get appBarToggleSidebar => 'Toggle sidebar (Tab)';

  @override
  String get appBarLibraryTheme => 'App theme';

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
