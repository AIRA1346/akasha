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

  @override
  String get sidebarHome => 'Home';

  @override
  String get sidebarExplore => 'Explore';

  @override
  String get sidebarLibrary => 'Library';

  @override
  String get sidebarCollections => 'Collections';

  @override
  String get sidebarGraph => 'Graph';

  @override
  String get sidebarTimeline => 'Timeline';

  @override
  String get sidebarMyLibraries => 'My Libraries';

  @override
  String get sidebarCreateMyLibraryPrompt => 'Create your own library';

  @override
  String get libraryMasterArchive => 'Master Archive';

  @override
  String get libraryCurated => 'Curated Library';

  @override
  String get libraryFiltered => 'Filtered Library';

  @override
  String libraryWorkCount(int count) {
    return '$count works';
  }

  @override
  String get itemKindWork => 'Work';

  @override
  String get sidebarRecentExplore => 'Recent';

  @override
  String get sidebarMyCollections => 'My Collections';

  @override
  String get sidebarViewAll => 'View all';

  @override
  String get sidebarNoCollections => 'No collections';

  @override
  String get searchPlaceholder =>
      'Search works, cast, timeline, places, concepts...';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get filterCloseTooltip => 'Close filter';

  @override
  String get appBarSyncUrlSettings => 'Sync URL Settings';

  @override
  String get appBarMoreToolsTooltip => 'More tools';

  @override
  String get previewDetails => 'Details';

  @override
  String get previewCoreInfo => 'Core Info';

  @override
  String get previewMyNotes => 'My Notes';

  @override
  String get previewMainCast => 'Main Cast';

  @override
  String get previewRelatedConcepts => 'Related Concepts';

  @override
  String get previewExploreNext => 'Explore Next';

  @override
  String get previewViewInCatalog => 'View in Catalog';

  @override
  String get previewAddPerson => 'Add Person';

  @override
  String get previewAddConcept => 'Add Concept';

  @override
  String get previewNoRating => 'No Rating';

  @override
  String get previewInfoNone => 'No info';

  @override
  String get previewGenre => 'Genre';

  @override
  String get previewAuthor => 'Author';

  @override
  String get previewStudio => 'Studio';

  @override
  String get previewType => 'Type';

  @override
  String get previewAliases => 'Aliases';

  @override
  String get previewDomain => 'Domain';

  @override
  String get previewTags => 'Tags';

  @override
  String get previewRating => 'Rating';

  @override
  String get previewViewInGraph => 'View in Graph';

  @override
  String catalogPrefix(String category) {
    return 'Catalog · $category';
  }

  @override
  String relatedRegistryWorks(String title) {
    return 'Catalog works related to $title';
  }

  @override
  String creatorWorks(String creator) {
    return '$creator\'s works';
  }

  @override
  String bridgeRelated(String bridge) {
    return 'Related to $bridge';
  }

  @override
  String get entityTypeWork => 'Work';

  @override
  String get entityTypePerson => 'Person';

  @override
  String get entityTypeConcept => 'Concept';

  @override
  String get entityTypeEvent => 'Event';

  @override
  String get entityTypePlace => 'Place';

  @override
  String get entityTypeOrganization => 'Organization';

  @override
  String get entityTypeCustom => 'Custom';

  @override
  String get entityTypePhenomenon => 'Legacy';

  @override
  String get actionRecord => 'Record';

  @override
  String get vaultSettingsTitle => 'Local Vault Settings';

  @override
  String vaultPathLinked(String path) {
    return 'Currently linked folder:\n$path';
  }

  @override
  String get vaultPathNotLinked =>
      'No folder linked. Link a Sanctum Vault folder to save records as markdown permanently.';

  @override
  String vaultStatusLinked(int count) {
    return 'Status: Linked · $count archive .md files';
  }

  @override
  String get vaultStatusPathNotFound =>
      'Status: Path not found (please link again)';

  @override
  String vaultBackupSuccess(String archiveName, int fileCount) {
    return 'Saved vault backup: $archiveName ($fileCount files)';
  }

  @override
  String vaultBackupFailed(String error) {
    return 'Vault backup failed: $error';
  }

  @override
  String get vaultBackupExport => 'Export Vault Backup ZIP';

  @override
  String get vaultViewTrash => 'View Vault Trash';

  @override
  String get vaultArchivingNotice =>
      '* Markdown files will be created in category folders (manga, game, animation, etc.). work_id is stored in YAML.';

  @override
  String get vaultAutoArchiveRegistry => 'Auto-archive catalog works';

  @override
  String get vaultAutoArchiveRegistryHelp =>
      'When enabled, automatically generates markdown for catalog works within the current filter. (Default: Off)';

  @override
  String get vaultAutoArchiveRegistryRunNow => 'Run catalog archiving now';

  @override
  String vaultHiddenRegistryManage(int count) {
    return 'Manage hidden catalog items ($count)';
  }

  @override
  String get vaultDisplayNameLabel => 'Display Name (Watchlist, etc.)';

  @override
  String get vaultDisplayNameDefault => 'User';

  @override
  String get vaultDisconnect => 'Disconnect';

  @override
  String get vaultSaveName => 'Save Name';

  @override
  String get vaultChangeFolder => 'Change Folder';

  @override
  String get vaultLinkFolder => 'Link Folder';

  @override
  String get trashRestoredSuccess => 'Successfully restored from trash.';

  @override
  String get trashRestoredFailedFileExists =>
      'Could not restore. File already exists at original location.';

  @override
  String get trashRestore => 'Restore';

  @override
  String get trashDeletePermanently => 'Delete Permanently';

  @override
  String trashDeleteConfirm(String fileName) {
    return 'Permanently delete \'$fileName\' from trash?\nThis action cannot be undone.';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get trashDeletedSuccess => 'Permanently deleted from trash.';

  @override
  String get trashDeleteFailedNotFound => 'Could not find file to delete.';

  @override
  String get vaultTrashTitle => 'Vault Trash';

  @override
  String get trashEmpty => 'Trash is empty.';

  @override
  String get trashRefresh => 'Refresh';

  @override
  String trashDeletedTime(String time) {
    return 'Deleted $time';
  }

  @override
  String get validationInputName => 'Please enter a name.';

  @override
  String archiveTitle(String type) {
    return 'Archive $type';
  }

  @override
  String archiveNameLabel(String type) {
    return '$type Name';
  }

  @override
  String get archiveAliasesLabel => 'Aliases (comma-separated, optional)';

  @override
  String get archiveAliasesHint => 'tiger, white tiger';

  @override
  String get archiveTagsLabel => 'Tags (semantic evaluation)';

  @override
  String get archiveMemoLabel => 'Notes (optional)';

  @override
  String get archiveNameOnly => 'Register name only (advanced)';

  @override
  String get archiveNameOnlyHelp => 'ID for linking only, no journal created';

  @override
  String get archiveAdd => 'Add to Archive';

  @override
  String get actionAdd => 'Add';

  @override
  String get archiveChooseType => 'Select Type to Add';

  @override
  String get archiveDescWork => 'Archive .md to Vault';

  @override
  String archiveDescEntity(String type) {
    return 'Archive .md to entities/$type';
  }

  @override
  String get validationSpecifyTagOrWork =>
      'Please specify at least one tag or work.';

  @override
  String get actionSave => 'Save';

  @override
  String get proposalSaved =>
      'Global catalog addition proposal saved. (Export from proposal box)';

  @override
  String get validationLinkVaultFirst => 'Please link a vault first.';

  @override
  String get draftRecoveryAvailable => 'Temporary draft available.';

  @override
  String journalDeleted(String title) {
    return 'Deleted journal for \'$title\'.';
  }

  @override
  String get journalSaveBeforeHtml =>
      'Please save the journal before exporting to HTML.';

  @override
  String vaultFileDeleted(String title) {
    return 'Deleted markdown file \'$title\'.';
  }

  @override
  String get statusSaving => 'Saving...';

  @override
  String get statusUnsaved => '● Unsaved';

  @override
  String statusSavedText(String time) {
    return 'Saved $time';
  }

  @override
  String statusDirtyHint(String saveLabel) {
    return 'Modified · Auto-saved locally · Use \'$saveLabel\' to reflect on dashboard';
  }

  @override
  String statusSavedHint(String time, String saveLabel) {
    return 'Saved $time · Auto-saved · Use \'$saveLabel\' to reflect on dashboard';
  }

  @override
  String statusReturnHint(String saveLabel) {
    return 'Use \'$saveLabel\' to return to dashboard preview';
  }

  @override
  String get actionSaveMd => 'Save MD';
}
