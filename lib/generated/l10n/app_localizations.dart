import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @browseLoadingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Loading global works catalog…'**
  String get browseLoadingCatalog;

  /// No description provided for @browseNoResults.
  ///
  /// In en, this message translates to:
  /// **'No works match your filters.'**
  String get browseNoResults;

  /// No description provided for @browseCatalogIndexed.
  ///
  /// In en, this message translates to:
  /// **'{loaded} / {total} works indexed'**
  String browseCatalogIndexed(int loaded, int total);

  /// No description provided for @browseLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more (+{count})'**
  String browseLoadMore(int count);

  /// No description provided for @settingsDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsDisplayLanguage;

  /// No description provided for @localeKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get localeKo;

  /// No description provided for @localeEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEn;

  /// No description provided for @appPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get appPreferencesTitle;

  /// No description provided for @appPreferencesDisplayScale.
  ///
  /// In en, this message translates to:
  /// **'Display scale'**
  String get appPreferencesDisplayScale;

  /// No description provided for @appPreferencesResetScale.
  ///
  /// In en, this message translates to:
  /// **'Reset to 100%'**
  String get appPreferencesResetScale;

  /// No description provided for @appPreferencesScaleHelp.
  ///
  /// In en, this message translates to:
  /// **'Adjust text and major control size across the app.'**
  String get appPreferencesScaleHelp;

  /// No description provided for @appPreferencesThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appPreferencesThemeTitle;

  /// No description provided for @appPreferencesThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the color palette.'**
  String get appPreferencesThemeSubtitle;

  /// No description provided for @appPreferencesVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault settings'**
  String get appPreferencesVaultTitle;

  /// No description provided for @appPreferencesVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage the storage folder, backups, and trash.'**
  String get appPreferencesVaultSubtitle;

  /// No description provided for @appPreferencesQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get appPreferencesQuit;

  /// No description provided for @appPreferencesClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appPreferencesClose;

  /// No description provided for @appBarToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar (Tab)'**
  String get appBarToggleSidebar;

  /// No description provided for @appBarLibraryTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appBarLibraryTheme;

  /// No description provided for @appBarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get appBarSearch;

  /// No description provided for @appBarTimelineCapture.
  ///
  /// In en, this message translates to:
  /// **'Timeline note'**
  String get appBarTimelineCapture;

  /// No description provided for @appBarCatalogInbox.
  ///
  /// In en, this message translates to:
  /// **'Catalog suggestions inbox'**
  String get appBarCatalogInbox;

  /// No description provided for @appBarClipboardImport.
  ///
  /// In en, this message translates to:
  /// **'Import AI markdown'**
  String get appBarClipboardImport;

  /// No description provided for @appBarSyncRegistry.
  ///
  /// In en, this message translates to:
  /// **'Sync global works catalog (long-press for settings)'**
  String get appBarSyncRegistry;

  /// No description provided for @appBarPromptTemplates.
  ///
  /// In en, this message translates to:
  /// **'Copy AI prompt templates'**
  String get appBarPromptTemplates;

  /// No description provided for @appBarClearRegistryCache.
  ///
  /// In en, this message translates to:
  /// **'Clear catalog JSON cache (not poster images)'**
  String get appBarClearRegistryCache;

  /// No description provided for @appBarVaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Local vault settings'**
  String get appBarVaultSettings;

  /// No description provided for @sidebarHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get sidebarHome;

  /// No description provided for @sidebarExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get sidebarExplore;

  /// No description provided for @sidebarLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get sidebarLibrary;

  /// No description provided for @sidebarCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get sidebarCollections;

  /// No description provided for @sidebarGraph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get sidebarGraph;

  /// No description provided for @sidebarTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get sidebarTimeline;

  /// No description provided for @sidebarMyLibraries.
  ///
  /// In en, this message translates to:
  /// **'My Libraries'**
  String get sidebarMyLibraries;

  /// No description provided for @sidebarCreateMyLibraryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your own library'**
  String get sidebarCreateMyLibraryPrompt;

  /// No description provided for @libraryMasterArchive.
  ///
  /// In en, this message translates to:
  /// **'Master Archive'**
  String get libraryMasterArchive;

  /// No description provided for @libraryCurated.
  ///
  /// In en, this message translates to:
  /// **'Curated Library'**
  String get libraryCurated;

  /// No description provided for @libraryFiltered.
  ///
  /// In en, this message translates to:
  /// **'Filtered Library'**
  String get libraryFiltered;

  /// No description provided for @libraryWorkCount.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String libraryWorkCount(int count);

  /// No description provided for @itemKindWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get itemKindWork;

  /// No description provided for @sidebarRecentExplore.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sidebarRecentExplore;

  /// No description provided for @sidebarMyCollections.
  ///
  /// In en, this message translates to:
  /// **'My Collections'**
  String get sidebarMyCollections;

  /// No description provided for @sidebarViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get sidebarViewAll;

  /// No description provided for @sidebarNoCollections.
  ///
  /// In en, this message translates to:
  /// **'No Collections'**
  String get sidebarNoCollections;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search works, cast, timeline, places, concepts...'**
  String get searchPlaceholder;

  /// No description provided for @filterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTooltip;

  /// No description provided for @filterCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close filter'**
  String get filterCloseTooltip;

  /// No description provided for @appBarSyncUrlSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync URL Settings'**
  String get appBarSyncUrlSettings;

  /// No description provided for @appBarMoreToolsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More tools'**
  String get appBarMoreToolsTooltip;

  /// No description provided for @previewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get previewDetails;

  /// No description provided for @previewCoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Core Info'**
  String get previewCoreInfo;

  /// No description provided for @previewMyNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get previewMyNotes;

  /// No description provided for @previewMainCast.
  ///
  /// In en, this message translates to:
  /// **'Main Cast'**
  String get previewMainCast;

  /// No description provided for @previewRelatedConcepts.
  ///
  /// In en, this message translates to:
  /// **'Related Concepts'**
  String get previewRelatedConcepts;

  /// No description provided for @previewExploreNext.
  ///
  /// In en, this message translates to:
  /// **'Explore Next'**
  String get previewExploreNext;

  /// No description provided for @previewViewInCatalog.
  ///
  /// In en, this message translates to:
  /// **'View in Catalog'**
  String get previewViewInCatalog;

  /// No description provided for @previewAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get previewAddPerson;

  /// No description provided for @previewAddConcept.
  ///
  /// In en, this message translates to:
  /// **'Add Concept'**
  String get previewAddConcept;

  /// No description provided for @previewNoRating.
  ///
  /// In en, this message translates to:
  /// **'No Rating'**
  String get previewNoRating;

  /// No description provided for @previewInfoNone.
  ///
  /// In en, this message translates to:
  /// **'No info'**
  String get previewInfoNone;

  /// No description provided for @previewGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get previewGenre;

  /// No description provided for @previewAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get previewAuthor;

  /// No description provided for @previewStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get previewStudio;

  /// No description provided for @previewType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get previewType;

  /// No description provided for @previewAliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get previewAliases;

  /// No description provided for @previewDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get previewDomain;

  /// No description provided for @previewTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get previewTags;

  /// No description provided for @previewRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get previewRating;

  /// No description provided for @previewViewInGraph.
  ///
  /// In en, this message translates to:
  /// **'View in Graph'**
  String get previewViewInGraph;

  /// No description provided for @catalogPrefix.
  ///
  /// In en, this message translates to:
  /// **'Catalog · {category}'**
  String catalogPrefix(String category);

  /// No description provided for @relatedRegistryWorks.
  ///
  /// In en, this message translates to:
  /// **'Catalog works related to {title}'**
  String relatedRegistryWorks(String title);

  /// No description provided for @creatorWorks.
  ///
  /// In en, this message translates to:
  /// **'{creator}\'s works'**
  String creatorWorks(String creator);

  /// No description provided for @bridgeRelated.
  ///
  /// In en, this message translates to:
  /// **'Related to {bridge}'**
  String bridgeRelated(String bridge);

  /// No description provided for @entityTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get entityTypeWork;

  /// No description provided for @entityTypePerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get entityTypePerson;

  /// No description provided for @entityTypeConcept.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get entityTypeConcept;

  /// No description provided for @entityTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get entityTypeEvent;

  /// No description provided for @entityTypePlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get entityTypePlace;

  /// No description provided for @entityTypeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get entityTypeOrganization;

  /// No description provided for @entityTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get entityTypeCustom;

  /// No description provided for @entityTypePhenomenon.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get entityTypePhenomenon;

  /// No description provided for @actionRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get actionRecord;

  /// No description provided for @vaultSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Vault Settings'**
  String get vaultSettingsTitle;

  /// No description provided for @vaultPathLinked.
  ///
  /// In en, this message translates to:
  /// **'Currently linked folder:\n{path}'**
  String vaultPathLinked(String path);

  /// No description provided for @vaultPathNotLinked.
  ///
  /// In en, this message translates to:
  /// **'No folder linked. Link a Sanctum Vault folder to save records as markdown permanently.'**
  String get vaultPathNotLinked;

  /// No description provided for @vaultStatusLinked.
  ///
  /// In en, this message translates to:
  /// **'Status: Linked · {count} archive .md files'**
  String vaultStatusLinked(int count);

  /// No description provided for @vaultStatusPathNotFound.
  ///
  /// In en, this message translates to:
  /// **'Status: Path not found (please link again)'**
  String get vaultStatusPathNotFound;

  /// No description provided for @vaultBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved vault backup: {archiveName} ({fileCount} files)'**
  String vaultBackupSuccess(String archiveName, int fileCount);

  /// No description provided for @vaultBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Vault backup failed: {error}'**
  String vaultBackupFailed(String error);

  /// No description provided for @vaultBackupExport.
  ///
  /// In en, this message translates to:
  /// **'Export Vault Backup ZIP'**
  String get vaultBackupExport;

  /// No description provided for @vaultViewTrash.
  ///
  /// In en, this message translates to:
  /// **'View Vault Trash'**
  String get vaultViewTrash;

  /// No description provided for @vaultArchivingNotice.
  ///
  /// In en, this message translates to:
  /// **'* Markdown files will be created in category folders (manga, game, animation, etc.). work_id is stored in YAML.'**
  String get vaultArchivingNotice;

  /// No description provided for @vaultAutoArchiveRegistry.
  ///
  /// In en, this message translates to:
  /// **'Auto-archive catalog works'**
  String get vaultAutoArchiveRegistry;

  /// No description provided for @vaultAutoArchiveRegistryHelp.
  ///
  /// In en, this message translates to:
  /// **'When enabled, automatically generates markdown for catalog works within the current filter. (Default: Off)'**
  String get vaultAutoArchiveRegistryHelp;

  /// No description provided for @vaultAutoArchiveRegistryRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run catalog archiving now'**
  String get vaultAutoArchiveRegistryRunNow;

  /// No description provided for @vaultHiddenRegistryManage.
  ///
  /// In en, this message translates to:
  /// **'Manage hidden catalog items ({count})'**
  String vaultHiddenRegistryManage(int count);

  /// No description provided for @vaultDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Watchlist, etc.)'**
  String get vaultDisplayNameLabel;

  /// No description provided for @vaultDisplayNameDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get vaultDisplayNameDefault;

  /// No description provided for @vaultDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get vaultDisconnect;

  /// No description provided for @vaultSaveName.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get vaultSaveName;

  /// No description provided for @vaultChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change Folder'**
  String get vaultChangeFolder;

  /// No description provided for @vaultLinkFolder.
  ///
  /// In en, this message translates to:
  /// **'Link Folder'**
  String get vaultLinkFolder;

  /// No description provided for @trashRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully restored from trash.'**
  String get trashRestoredSuccess;

  /// No description provided for @trashRestoredFailedFileExists.
  ///
  /// In en, this message translates to:
  /// **'Could not restore. File already exists at original location.'**
  String get trashRestoredFailedFileExists;

  /// No description provided for @trashRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get trashRestore;

  /// No description provided for @trashDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get trashDeletePermanently;

  /// No description provided for @trashDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \'{fileName}\' from trash?\nThis action cannot be undone.'**
  String trashDeleteConfirm(String fileName);

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @trashDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted from trash.'**
  String get trashDeletedSuccess;

  /// No description provided for @trashDeleteFailedNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find file to delete.'**
  String get trashDeleteFailedNotFound;

  /// No description provided for @vaultTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault Trash'**
  String get vaultTrashTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty.'**
  String get trashEmpty;

  /// No description provided for @trashRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get trashRefresh;

  /// No description provided for @trashDeletedTime.
  ///
  /// In en, this message translates to:
  /// **'Deleted {time}'**
  String trashDeletedTime(String time);

  /// No description provided for @validationInputName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get validationInputName;

  /// No description provided for @archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {type}'**
  String archiveTitle(String type);

  /// No description provided for @archiveNameLabel.
  ///
  /// In en, this message translates to:
  /// **'{type} Name'**
  String archiveNameLabel(String type);

  /// No description provided for @archiveAliasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Aliases (comma-separated, optional)'**
  String get archiveAliasesLabel;

  /// No description provided for @archiveAliasesHint.
  ///
  /// In en, this message translates to:
  /// **'tiger, white tiger'**
  String get archiveAliasesHint;

  /// No description provided for @archiveTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (semantic evaluation)'**
  String get archiveTagsLabel;

  /// No description provided for @archiveMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get archiveMemoLabel;

  /// No description provided for @archiveNameOnly.
  ///
  /// In en, this message translates to:
  /// **'Register name only (advanced)'**
  String get archiveNameOnly;

  /// No description provided for @archiveNameOnlyHelp.
  ///
  /// In en, this message translates to:
  /// **'ID for linking only, no journal created'**
  String get archiveNameOnlyHelp;

  /// No description provided for @archiveAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to Archive'**
  String get archiveAdd;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @archiveChooseType.
  ///
  /// In en, this message translates to:
  /// **'Select Type to Add'**
  String get archiveChooseType;

  /// No description provided for @archiveDescWork.
  ///
  /// In en, this message translates to:
  /// **'Archive .md to Vault'**
  String get archiveDescWork;

  /// No description provided for @archiveDescEntity.
  ///
  /// In en, this message translates to:
  /// **'Archive .md to entities/{type}'**
  String archiveDescEntity(String type);

  /// No description provided for @validationSpecifyTagOrWork.
  ///
  /// In en, this message translates to:
  /// **'Please specify at least one tag or work.'**
  String get validationSpecifyTagOrWork;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @proposalSaved.
  ///
  /// In en, this message translates to:
  /// **'Global catalog addition proposal saved. (Export from proposal box)'**
  String get proposalSaved;

  /// No description provided for @validationLinkVaultFirst.
  ///
  /// In en, this message translates to:
  /// **'Please link a vault first.'**
  String get validationLinkVaultFirst;

  /// No description provided for @draftRecoveryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Temporary draft available.'**
  String get draftRecoveryAvailable;

  /// No description provided for @journalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted journal for \'{title}\'.'**
  String journalDeleted(String title);

  /// No description provided for @journalSaveBeforeHtml.
  ///
  /// In en, this message translates to:
  /// **'Please save the journal before exporting to HTML.'**
  String get journalSaveBeforeHtml;

  /// No description provided for @vaultFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted markdown file \'{title}\'.'**
  String vaultFileDeleted(String title);

  /// No description provided for @statusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get statusSaving;

  /// No description provided for @statusUnsaved.
  ///
  /// In en, this message translates to:
  /// **'● Unsaved'**
  String get statusUnsaved;

  /// No description provided for @statusSavedText.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String statusSavedText(String time);

  /// No description provided for @statusDirtyHint.
  ///
  /// In en, this message translates to:
  /// **'Modified · Auto-saved locally · Use \'{saveLabel}\' to reflect on dashboard'**
  String statusDirtyHint(String saveLabel);

  /// No description provided for @statusSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Saved {time} · Auto-saved · Use \'{saveLabel}\' to reflect on dashboard'**
  String statusSavedHint(String time, String saveLabel);

  /// No description provided for @statusReturnHint.
  ///
  /// In en, this message translates to:
  /// **'Use \'{saveLabel}\' to return to dashboard preview'**
  String statusReturnHint(String saveLabel);

  /// No description provided for @actionSaveMd.
  ///
  /// In en, this message translates to:
  /// **'Save md'**
  String get actionSaveMd;

  /// No description provided for @mediaCategoryManga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get mediaCategoryManga;

  /// No description provided for @mediaCategoryWebtoon.
  ///
  /// In en, this message translates to:
  /// **'Webtoon'**
  String get mediaCategoryWebtoon;

  /// No description provided for @mediaCategoryAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get mediaCategoryAnimation;

  /// No description provided for @mediaCategoryGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get mediaCategoryGame;

  /// No description provided for @mediaCategoryBook.
  ///
  /// In en, this message translates to:
  /// **'Book/Novel/Light Novel'**
  String get mediaCategoryBook;

  /// No description provided for @mediaCategoryMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get mediaCategoryMovie;

  /// No description provided for @mediaCategoryDrama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get mediaCategoryDrama;

  /// No description provided for @statusContentWorkSerializing.
  ///
  /// In en, this message translates to:
  /// **'Serializing'**
  String get statusContentWorkSerializing;

  /// No description provided for @statusContentWorkHiatus.
  ///
  /// In en, this message translates to:
  /// **'Hiatus'**
  String get statusContentWorkHiatus;

  /// No description provided for @statusContentWorkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusContentWorkCompleted;

  /// No description provided for @statusContentMyNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Plan to Watch'**
  String get statusContentMyNotStarted;

  /// No description provided for @statusContentMyWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get statusContentMyWatching;

  /// No description provided for @statusContentMyFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusContentMyFinished;

  /// No description provided for @statusContentMyDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get statusContentMyDropped;

  /// No description provided for @statusGameWorkReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get statusGameWorkReleased;

  /// No description provided for @statusGameWorkEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early Access'**
  String get statusGameWorkEarlyAccess;

  /// No description provided for @statusGameWorkUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusGameWorkUpcoming;

  /// No description provided for @statusGameMyBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get statusGameMyBacklog;

  /// No description provided for @statusGameMyPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get statusGameMyPlaying;

  /// No description provided for @statusGameMyCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get statusGameMyCleared;

  /// No description provided for @statusGameMyAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get statusGameMyAbandoned;

  /// No description provided for @sortCriteriaManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Order'**
  String get sortCriteriaManual;

  /// No description provided for @sortCriteriaTitle.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get sortCriteriaTitle;

  /// No description provided for @sortCriteriaRating.
  ///
  /// In en, this message translates to:
  /// **'Highest Rating'**
  String get sortCriteriaRating;

  /// No description provided for @sortCriteriaRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get sortCriteriaRecentlyAdded;

  /// No description provided for @sortCriteriaYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get sortCriteriaYear;

  /// No description provided for @addWorkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New Work (Add to Archive)'**
  String get addWorkDialogTitle;

  /// No description provided for @registryWorkSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Global Catalog'**
  String get registryWorkSearch;

  /// No description provided for @labelTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get labelTitle;

  /// No description provided for @labelCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator / Studio'**
  String get labelCreator;

  /// No description provided for @labelReleaseYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get labelReleaseYear;

  /// No description provided for @posterImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Poster Image (Web URL or Local File)'**
  String get posterImageLabel;

  /// No description provided for @posterUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter https://... or local path'**
  String get posterUrlHint;

  /// No description provided for @tooltipPickLocalImage.
  ///
  /// In en, this message translates to:
  /// **'Select Local Image File'**
  String get tooltipPickLocalImage;

  /// No description provided for @tooltipWebImageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Web Images'**
  String get tooltipWebImageSearch;

  /// No description provided for @myRating.
  ///
  /// In en, this message translates to:
  /// **'My Rating'**
  String get myRating;

  /// No description provided for @labelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// No description provided for @labelWorkStatus.
  ///
  /// In en, this message translates to:
  /// **'Work Status'**
  String get labelWorkStatus;

  /// No description provided for @labelMyStatus.
  ///
  /// In en, this message translates to:
  /// **'My Status'**
  String get labelMyStatus;

  /// No description provided for @actionRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get actionRegister;

  /// No description provided for @validationEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get validationEnterTitle;

  /// No description provided for @catalogAddContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Catalog — Suggest New Work'**
  String get catalogAddContributionTitle;

  /// No description provided for @labelTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get labelTitleRequired;

  /// No description provided for @labelPosterUrl.
  ///
  /// In en, this message translates to:
  /// **'Poster URL (https)'**
  String get labelPosterUrl;

  /// No description provided for @tooltipImageSearch.
  ///
  /// In en, this message translates to:
  /// **'Image Search'**
  String get tooltipImageSearch;

  /// No description provided for @labelDescriptionBrief.
  ///
  /// In en, this message translates to:
  /// **'Description (write briefly)'**
  String get labelDescriptionBrief;

  /// No description provided for @labelAnilistId.
  ///
  /// In en, this message translates to:
  /// **'AniList ID (optional, numbers only)'**
  String get labelAnilistId;

  /// No description provided for @labelProposalNote.
  ///
  /// In en, this message translates to:
  /// **'Proposal Note (optional)'**
  String get labelProposalNote;

  /// No description provided for @actionSaveProposal.
  ///
  /// In en, this message translates to:
  /// **'Save Proposal'**
  String get actionSaveProposal;

  /// No description provided for @validationPosterHttpsOnly.
  ///
  /// In en, this message translates to:
  /// **'Poster must be an https URL.'**
  String get validationPosterHttpsOnly;

  /// No description provided for @catalogContributionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Proposals are saved locally. They will be reflected in the global catalog after review, merge into akasha-db, and app sync.'**
  String get catalogContributionDisclaimer;

  /// No description provided for @catalogFixContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Catalog — Suggest Fix'**
  String get catalogFixContributionTitle;

  /// No description provided for @labelWhatIsWrong.
  ///
  /// In en, this message translates to:
  /// **'What is wrong? *'**
  String get labelWhatIsWrong;

  /// No description provided for @hintWhatIsWrong.
  ///
  /// In en, this message translates to:
  /// **'e.g. Poster image belongs to a different work'**
  String get hintWhatIsWrong;

  /// No description provided for @fixPosterUrl.
  ///
  /// In en, this message translates to:
  /// **'Fix Poster URL'**
  String get fixPosterUrl;

  /// No description provided for @labelProposedPosterUrl.
  ///
  /// In en, this message translates to:
  /// **'Proposed Poster URL'**
  String get labelProposedPosterUrl;

  /// No description provided for @fixReleaseYear.
  ///
  /// In en, this message translates to:
  /// **'Fix Release Year'**
  String get fixReleaseYear;

  /// No description provided for @labelProposedYear.
  ///
  /// In en, this message translates to:
  /// **'Proposed Year'**
  String get labelProposedYear;

  /// No description provided for @fixTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix Title'**
  String get fixTitle;

  /// No description provided for @labelProposedTitle.
  ///
  /// In en, this message translates to:
  /// **'Proposed Title'**
  String get labelProposedTitle;

  /// No description provided for @fixCreator.
  ///
  /// In en, this message translates to:
  /// **'Fix Creator / Studio'**
  String get fixCreator;

  /// No description provided for @labelProposedCreator.
  ///
  /// In en, this message translates to:
  /// **'Proposed Creator / Studio'**
  String get labelProposedCreator;

  /// No description provided for @labelAdditionalNote.
  ///
  /// In en, this message translates to:
  /// **'Additional Note'**
  String get labelAdditionalNote;

  /// No description provided for @validationEnterIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue.'**
  String get validationEnterIssue;

  /// No description provided for @validationSelectFixField.
  ///
  /// In en, this message translates to:
  /// **'Please select a field to fix.'**
  String get validationSelectFixField;

  /// No description provided for @validationPosterHttpsRequired.
  ///
  /// In en, this message translates to:
  /// **'Poster must be an https URL.'**
  String get validationPosterHttpsRequired;

  /// No description provided for @validationEnterYearNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter the year as a number.'**
  String get validationEnterYearNumber;

  /// No description provided for @clipboardImportTitle.
  ///
  /// In en, this message translates to:
  /// **'🤖 AI Markdown Import'**
  String get clipboardImportTitle;

  /// No description provided for @clipboardImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste AI-generated markdown text here. It will be parsed and added to your work list.'**
  String get clipboardImportDescription;

  /// No description provided for @untitledWork.
  ///
  /// In en, this message translates to:
  /// **'Untitled Work'**
  String get untitledWork;

  /// No description provided for @clipboardImportAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is already in the archive.'**
  String clipboardImportAlreadyExists(String title);

  /// No description provided for @clipboardImportAdded.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" added (work_id: {workId})'**
  String clipboardImportAdded(String title, String workId);

  /// No description provided for @clipboardImportParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Parsing failed: {error}'**
  String clipboardImportParseFailed(String error);

  /// No description provided for @actionParseAndImport.
  ///
  /// In en, this message translates to:
  /// **'Parse & Import'**
  String get actionParseAndImport;

  /// No description provided for @noWorksInCatalogVault.
  ///
  /// In en, this message translates to:
  /// **'No works in catalog or vault.'**
  String get noWorksInCatalogVault;

  /// No description provided for @labelSelectWork.
  ///
  /// In en, this message translates to:
  /// **'Select Work'**
  String get labelSelectWork;

  /// No description provided for @optionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get optionNone;

  /// No description provided for @createCastFromWork.
  ///
  /// In en, this message translates to:
  /// **'Create Cast from Selected Work'**
  String get createCastFromWork;

  /// No description provided for @labelCollectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get labelCollectionName;

  /// No description provided for @labelMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get labelMode;

  /// No description provided for @modeFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter (tags · works · kind)'**
  String get modeFilter;

  /// No description provided for @modeCurated.
  ///
  /// In en, this message translates to:
  /// **'Curated (manual selection)'**
  String get modeCurated;

  /// No description provided for @collectionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Collection'**
  String get collectionAddTitle;

  /// No description provided for @collectionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection Settings'**
  String get collectionEditTitle;

  /// No description provided for @noEntitiesInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No Person, Concept, or other entities in catalog.'**
  String get noEntitiesInCatalog;

  /// No description provided for @selectedCountReorderHint.
  ///
  /// In en, this message translates to:
  /// **'{count} selected · reorder in gallery'**
  String selectedCountReorderHint(int count);

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get deleteCollectionTitle;

  /// No description provided for @deleteCollectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this collection? Entity data will be preserved.'**
  String get deleteCollectionConfirm;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @presetAvailabilityNote.
  ///
  /// In en, this message translates to:
  /// **'Only enabled when the work exists in vault or catalog.'**
  String get presetAvailabilityNote;

  /// No description provided for @customCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Manually'**
  String get customCreate;

  /// No description provided for @customCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Tag-based · Work-based · Mixed — configure below, then tap \"Add\"'**
  String get customCreateDescription;

  /// No description provided for @tabExistingLink.
  ///
  /// In en, this message translates to:
  /// **'Existing Links'**
  String get tabExistingLink;

  /// No description provided for @tabCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get tabCreateNew;

  /// No description provided for @hintSearchNameAlias.
  ///
  /// In en, this message translates to:
  /// **'Search by name or alias'**
  String get hintSearchNameAlias;

  /// No description provided for @noEntitiesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No entities to link.'**
  String get noEntitiesAvailable;

  /// No description provided for @noMatchingEntity.
  ///
  /// In en, this message translates to:
  /// **'No items matching \"{query}\".'**
  String noMatchingEntity(String query);

  /// No description provided for @sectionRelatedToWork.
  ///
  /// In en, this message translates to:
  /// **'Related to this Work'**
  String get sectionRelatedToWork;

  /// No description provided for @sectionSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get sectionSearchResults;

  /// No description provided for @createEntityAndLink.
  ///
  /// In en, this message translates to:
  /// **'Register a new {typeLabel} not in the catalog and link it to this work.'**
  String createEntityAndLink(String typeLabel);

  /// No description provided for @useSearchQueryAsName.
  ///
  /// In en, this message translates to:
  /// **'Use search term as name'**
  String get useSearchQueryAsName;

  /// No description provided for @createNewEntityType.
  ///
  /// In en, this message translates to:
  /// **'Create New {typeLabel}'**
  String createNewEntityType(String typeLabel);

  /// No description provided for @subtitleRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations · Person · Event · Concept · Place · Org'**
  String get subtitleRecommendations;

  /// No description provided for @subtitleSeedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not in your catalog · Can link from seed catalog'**
  String get subtitleSeedAvailable;

  /// No description provided for @subtitleCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog · Person · Event · Concept · Place · Org'**
  String get subtitleCatalog;

  /// No description provided for @journalQuickCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Memo'**
  String get journalQuickCaptureTitle;

  /// No description provided for @labelBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get labelBody;

  /// No description provided for @hintJournalBody.
  ///
  /// In en, this message translates to:
  /// **'Ideas, memos, thoughts…'**
  String get hintJournalBody;

  /// No description provided for @labelTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get labelTitleOptional;

  /// No description provided for @hintTitleAutoFill.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use beginning of body'**
  String get hintTitleAutoFill;

  /// No description provided for @personalLibraryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Personal Library'**
  String get personalLibraryAddTitle;

  /// No description provided for @labelLibraryName.
  ///
  /// In en, this message translates to:
  /// **'Library Name'**
  String get labelLibraryName;

  /// No description provided for @hintLibraryName.
  ///
  /// In en, this message translates to:
  /// **'e.g. All-time Favorites, Reading Backlog 2026…'**
  String get hintLibraryName;

  /// No description provided for @helperLibraryCreate.
  ///
  /// In en, this message translates to:
  /// **'Add works after creating. Filters can be adjusted in settings.'**
  String get helperLibraryCreate;

  /// No description provided for @personalLibraryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Library Settings'**
  String get personalLibraryEditTitle;

  /// No description provided for @hintLibraryNameEdit.
  ///
  /// In en, this message translates to:
  /// **'e.g. All-time Favorites, Completed List…'**
  String get hintLibraryNameEdit;

  /// No description provided for @helperMasterArchiveReadonly.
  ///
  /// In en, this message translates to:
  /// **'The master_archive name cannot be changed.'**
  String get helperMasterArchiveReadonly;

  /// No description provided for @helperCuratedMode.
  ///
  /// In en, this message translates to:
  /// **'Only included works are shown. Filters narrow further.'**
  String get helperCuratedMode;

  /// No description provided for @helperFilterMode.
  ///
  /// In en, this message translates to:
  /// **'Only archived vault works are shown via filters.'**
  String get helperFilterMode;

  /// No description provided for @addWorkSearch.
  ///
  /// In en, this message translates to:
  /// **'Add Work (Search)'**
  String get addWorkSearch;

  /// No description provided for @includedWorksCount.
  ///
  /// In en, this message translates to:
  /// **'Included Works ({count})'**
  String includedWorksCount(int count);

  /// No description provided for @noIncludedWorks.
  ///
  /// In en, this message translates to:
  /// **'No works included yet.'**
  String get noIncludedWorks;

  /// No description provided for @cleanOrphanIds.
  ///
  /// In en, this message translates to:
  /// **'Clean Orphan IDs ({count})'**
  String cleanOrphanIds(int count);

  /// No description provided for @labelCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category Filter (multi-select)'**
  String get labelCategoryFilter;

  /// No description provided for @labelWorkStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Work Status Filter (multi-select)'**
  String get labelWorkStatusFilter;

  /// No description provided for @labelMyStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'My Status Filter (multi-select)'**
  String get labelMyStatusFilter;

  /// No description provided for @promptTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Prompt Template'**
  String get promptTemplateTitle;

  /// No description provided for @promptTemplateDescription.
  ///
  /// In en, this message translates to:
  /// **'Provide this template to an AI to easily get properly formatted markdown.'**
  String get promptTemplateDescription;

  /// No description provided for @templateCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Template copied to clipboard.'**
  String get templateCopiedToClipboard;

  /// No description provided for @registrySyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Catalog Sync'**
  String get registrySyncTitle;

  /// No description provided for @lastSyncTime.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncTime(String time);

  /// No description provided for @actionSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get actionSyncNow;

  /// No description provided for @labelCustomDbUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom Catalog DB Base URL'**
  String get labelCustomDbUrl;

  /// No description provided for @customDbUrlDescription.
  ///
  /// In en, this message translates to:
  /// **'Downloads manifest.json, search_index.json, and shards/ files from this address.'**
  String get customDbUrlDescription;

  /// No description provided for @syncUrlChanged.
  ///
  /// In en, this message translates to:
  /// **'Sync URL has been updated.'**
  String get syncUrlChanged;

  /// No description provided for @actionSaveUrl.
  ///
  /// In en, this message translates to:
  /// **'Save URL'**
  String get actionSaveUrl;

  /// No description provided for @timelineQuickCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline Entry'**
  String get timelineQuickCaptureTitle;

  /// No description provided for @hintTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s thoughts, diary, ideas…'**
  String get hintTimelineBody;

  /// No description provided for @labelWorkLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Link Work (optional)'**
  String get labelWorkLinkOptional;

  /// No description provided for @optionNoLink.
  ///
  /// In en, this message translates to:
  /// **'No Link'**
  String get optionNoLink;

  /// No description provided for @timelineSaveLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Saved to vault/timeline/.'**
  String get timelineSaveLocationInfo;

  /// No description provided for @workLinkPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Work'**
  String get workLinkPickerTitle;

  /// No description provided for @hintSearchTitleCreatorId.
  ///
  /// In en, this message translates to:
  /// **'Search by title, creator, or work_id'**
  String get hintSearchTitleCreatorId;

  /// No description provided for @workLinkPickerDescription.
  ///
  /// In en, this message translates to:
  /// **'Link library works to the document as [[links]].'**
  String get workLinkPickerDescription;

  /// No description provided for @noOtherWorksToLink.
  ///
  /// In en, this message translates to:
  /// **'No other works to link.'**
  String get noOtherWorksToLink;

  /// No description provided for @noMatchingWork.
  ///
  /// In en, this message translates to:
  /// **'No works matching \"{query}\".'**
  String noMatchingWork(String query);

  /// No description provided for @catalogContributionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog Proposals ({count})'**
  String catalogContributionsTitle(int count);

  /// No description provided for @noSavedProposals.
  ///
  /// In en, this message translates to:
  /// **'No saved proposals.'**
  String get noSavedProposals;

  /// No description provided for @suggestNewWork.
  ///
  /// In en, this message translates to:
  /// **'Suggest New Work'**
  String get suggestNewWork;

  /// No description provided for @actionCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get actionCopyJson;

  /// No description provided for @actionOpenGithubIssue.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub Issue'**
  String get actionOpenGithubIssue;

  /// No description provided for @actionCopyAllJson.
  ///
  /// In en, this message translates to:
  /// **'Copy All JSON'**
  String get actionCopyAllJson;

  /// No description provided for @proposalJsonCopied.
  ///
  /// In en, this message translates to:
  /// **'Proposal JSON copied to clipboard.'**
  String get proposalJsonCopied;

  /// No description provided for @jsonCopiedWithFile.
  ///
  /// In en, this message translates to:
  /// **'JSON copied · File: {path}'**
  String jsonCopiedWithFile(String path);

  /// No description provided for @jsonCopiedFileFailed.
  ///
  /// In en, this message translates to:
  /// **'JSON copied (file save failed: {error})'**
  String jsonCopiedFileFailed(String error);

  /// No description provided for @deleteUnsavedWarning.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes will also be lost.'**
  String get deleteUnsavedWarning;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Work'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteConfirmVault.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from the archive?\nThe local vault .md file will be permanently deleted.{unsavedNote}\nIt won\'t disappear from browse/catalog lists, and auto-archiving may recreate the .md.'**
  String detailDeleteConfirmVault(String title, String unsavedNote);

  /// No description provided for @detailDeleteConfirmNoVault.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from the list?\n(Demo mode — .md files will be deleted when vault is connected){unsavedNote}'**
  String detailDeleteConfirmNoVault(String title, String unsavedNote);

  /// No description provided for @workbenchCloseTabDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get workbenchCloseTabDialogTitle;

  /// No description provided for @workbenchCloseTabDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to close without saving?'**
  String get workbenchCloseTabDialogMessage;

  /// No description provided for @workbenchCloseTabDialogSaveAndClose.
  ///
  /// In en, this message translates to:
  /// **'Save & Close'**
  String get workbenchCloseTabDialogSaveAndClose;

  /// No description provided for @workbenchCloseTabDialogDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get workbenchCloseTabDialogDiscard;

  /// No description provided for @workbenchIncomingLinksRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Incoming Links'**
  String get workbenchIncomingLinksRefresh;

  /// No description provided for @workbenchBreadcrumbLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get workbenchBreadcrumbLibrary;

  /// No description provided for @workbenchBreadcrumbWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workbenchBreadcrumbWork;

  /// No description provided for @workbenchTabConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get workbenchTabConnections;

  /// No description provided for @workbenchTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get workbenchTabDetails;

  /// No description provided for @workbenchTabType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get workbenchTabType;

  /// No description provided for @workbenchTabConnectionCount.
  ///
  /// In en, this message translates to:
  /// **'Connections Count'**
  String get workbenchTabConnectionCount;

  /// No description provided for @workbenchTabAliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get workbenchTabAliases;

  /// No description provided for @workbenchTabStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Storage Path'**
  String get workbenchTabStoragePath;

  /// No description provided for @helpWorkbenchConnectionExplain.
  ///
  /// In en, this message translates to:
  /// **'Use Add in each section to connect entities. People go into cast slots; other entities are inserted as [[links]] in the journal body.'**
  String get helpWorkbenchConnectionExplain;

  /// No description provided for @helpEntityConnectionExplain.
  ///
  /// In en, this message translates to:
  /// **'Use Add in each section to connect records. [[links]] are inserted into the journal body.'**
  String get helpEntityConnectionExplain;

  /// No description provided for @workbenchCastSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Cast'**
  String get workbenchCastSectionTitle;

  /// No description provided for @workbenchQuotesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'🎬 Moments & Quotes'**
  String get workbenchQuotesSectionTitle;

  /// No description provided for @workbenchSynopsisSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'📋 Synopsis'**
  String get workbenchSynopsisSectionTitle;

  /// No description provided for @workbenchGallerySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'🖼 Gallery'**
  String get workbenchGallerySectionTitle;

  /// No description provided for @workbenchMemoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'📝 Notes'**
  String get workbenchMemoSectionTitle;

  /// No description provided for @workbenchEditorAddSection.
  ///
  /// In en, this message translates to:
  /// **'Insert Section'**
  String get workbenchEditorAddSection;

  /// No description provided for @workbenchEditorAddSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get workbenchEditorAddSectionTitle;

  /// No description provided for @workbenchEditorFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get workbenchEditorFind;

  /// No description provided for @workbenchEditorReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get workbenchEditorReplace;

  /// No description provided for @workbenchEditorNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get workbenchEditorNext;

  /// No description provided for @workbenchEditorPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get workbenchEditorPrev;

  /// No description provided for @sidebarRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sidebarRecent;

  /// No description provided for @labelDashboardSearchWorks.
  ///
  /// In en, this message translates to:
  /// **'Search Works'**
  String get labelDashboardSearchWorks;

  /// No description provided for @labelDashboardExploreEntities.
  ///
  /// In en, this message translates to:
  /// **'Explore Entities'**
  String get labelDashboardExploreEntities;

  /// No description provided for @labelDashboardConnectionMap.
  ///
  /// In en, this message translates to:
  /// **'Connection Map'**
  String get labelDashboardConnectionMap;

  /// No description provided for @labelDashboardAllBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse All'**
  String get labelDashboardAllBrowse;

  /// No description provided for @labelDashboardWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get labelDashboardWrite;

  /// No description provided for @akashaPromptTemplate.
  ///
  /// In en, this message translates to:
  /// **'You are a subculture (manga, game, anime, book) archiving expert.\nPlease write the requested work information in a markdown document, including the YAML Front-Matter format below.\n\n---\nwork_id: \"\" (Leave empty for AKASHA to auto-match or assign a custom ID)\ntitle: \"Exact Title of the Work\"\ncategory: manga | game | animation | book | movie | drama (Choose one)\ncreator: \"Creator / Studio / Director etc.\"\nrelease_year: Year of release or serialization start (number only, e.g. 2011)\nrating: 5.0 (Float in range 0.0~5.0)\nwork_status: \"serializing\" | \"hiatus\" | \"completed\" (For game category: \"released\" | \"earlyAccess\" | \"upcoming\")\nmy_status: \"notStarted\" | \"watching\" | \"finished\" | \"dropped\" (For game category: \"backlog\" | \"playing\" | \"cleared\" | \"abandoned\")\nis_hall_of_fame: true | false (Is all-time favorite)\ntags: [tag1, tag2] (e.g. [youth, touching, music])\nposter: \"\" (Leave empty)\nadded_at: \"Current date & time (ISO 8601, e.g. 2026-06-05T19:00:00)\"\n---\n\n# 👥 Cast\n\n# 🎬 Moments & Quotes\n> \"Moment description or quote\" — Character name / Context description\n\n# 📋 Synopsis\n\n# 🖼 Gallery\n\n# 📝 Notes\n'**
  String get akashaPromptTemplate;

  /// No description provided for @labelTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get labelTags;

  /// No description provided for @recordKindTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get recordKindTimeline;

  /// No description provided for @recordKindJournal.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get recordKindJournal;

  /// No description provided for @recordKindWorkJournal.
  ///
  /// In en, this message translates to:
  /// **'Work Journal'**
  String get recordKindWorkJournal;

  /// No description provided for @recordKindEntityJournal.
  ///
  /// In en, this message translates to:
  /// **'Entity Journal'**
  String get recordKindEntityJournal;

  /// No description provided for @recordKindFreeformJournal.
  ///
  /// In en, this message translates to:
  /// **'Freeform Journal'**
  String get recordKindFreeformJournal;

  /// No description provided for @connectedRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'Connected Records ({count})'**
  String connectedRecordsCount(int count);

  /// No description provided for @titleUpdateNeededCount.
  ///
  /// In en, this message translates to:
  /// **'Title update needed ({count})'**
  String titleUpdateNeededCount(int count);

  /// No description provided for @sameDayRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'Same Day Records · {date} ({count})'**
  String sameDayRecordsCount(String date, int count);

  /// No description provided for @actionCreateMd.
  ///
  /// In en, this message translates to:
  /// **'Create md'**
  String get actionCreateMd;

  /// No description provided for @actionSaveAndAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save & Add to Library'**
  String get actionSaveAndAddToLibrary;

  /// No description provided for @workbenchCloseTabMessageWithTitle.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes in \"{title}\".'**
  String workbenchCloseTabMessageWithTitle(String title);

  /// No description provided for @workbenchCloseTabMessageWithTitleNoSave.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes in \"{title}\".\nPlease select this tab first to save changes.'**
  String workbenchCloseTabMessageWithTitleNoSave(String title);

  /// No description provided for @entityJournalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the entity journal for \"{title}\"?'**
  String entityJournalDeleteConfirm(String title);

  /// No description provided for @entityJournalPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'(Awaiting record)'**
  String get entityJournalPlaceholderBody;

  /// No description provided for @entityJournalSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved entity journal for \"{title}\".'**
  String entityJournalSaveSuccess(String title);

  /// No description provided for @errorVaultRequired.
  ///
  /// In en, this message translates to:
  /// **'Please link the vault first.'**
  String get errorVaultRequired;

  /// No description provided for @errorEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Please enter the body text.'**
  String get errorEmptyBody;

  /// No description provided for @errorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String errorSaveFailed(String error);

  /// No description provided for @errorNoMdFileToDelete.
  ///
  /// In en, this message translates to:
  /// **'No md file found to delete.'**
  String get errorNoMdFileToDelete;

  /// No description provided for @errorCatalogRequired.
  ///
  /// In en, this message translates to:
  /// **'Catalog connection is required.'**
  String get errorCatalogRequired;

  /// No description provided for @helpWorkbenchCastEditorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add members using \"Add Person\" on the right to display them as cards in the preview.'**
  String get helpWorkbenchCastEditorEmpty;

  /// No description provided for @hintCastRole.
  ///
  /// In en, this message translates to:
  /// **'Role (e.g. Protagonist)'**
  String get hintCastRole;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get actionAddImage;

  /// No description provided for @helpWorkbenchGalleryEditorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop images, or use paste/add to insert screenshots and collages.'**
  String get helpWorkbenchGalleryEditorEmpty;

  /// No description provided for @hintQuotesEditor.
  ///
  /// In en, this message translates to:
  /// **'Enter one quote per line.'**
  String get hintQuotesEditor;

  /// No description provided for @errorAddImageVaultRequired.
  ///
  /// In en, this message translates to:
  /// **'Adding images is available after connecting the Sanctum vault.'**
  String get errorAddImageVaultRequired;

  /// No description provided for @errorPasteVaultRequired.
  ///
  /// In en, this message translates to:
  /// **'Pasting is available after connecting the Sanctum vault.'**
  String get errorPasteVaultRequired;

  /// No description provided for @errorNoImageInClipboard.
  ///
  /// In en, this message translates to:
  /// **'No image found in the clipboard.'**
  String get errorNoImageInClipboard;

  /// No description provided for @hintSynopsisEditor.
  ///
  /// In en, this message translates to:
  /// **'Write the plot, world setting, background, etc.'**
  String get hintSynopsisEditor;

  /// No description provided for @hintMemoEditor.
  ///
  /// In en, this message translates to:
  /// **'Thoughts, reviews, notes. Use \"Add\" on the right to insert [[links]].'**
  String get hintMemoEditor;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get navCollections;

  /// No description provided for @errorVaultRequiredToAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Please connect the vault first to add to the library.'**
  String get errorVaultRequiredToAddToLibrary;

  /// No description provided for @alreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Already in the library \"{name}\".'**
  String alreadyInLibrary(String name);

  /// No description provided for @addedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to the library \"{name}\".'**
  String addedToLibrary(String name);

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @errorArchiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Archive failed: {error}'**
  String errorArchiveFailed(String error);

  /// No description provided for @successRegistryCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared registry cache and restored bundle dictionary.'**
  String get successRegistryCacheCleared;

  /// No description provided for @errorClearCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String errorClearCacheFailed(String error);

  /// No description provided for @labelDashboardContinueExplore.
  ///
  /// In en, this message translates to:
  /// **'Continue Exploring'**
  String get labelDashboardContinueExplore;

  /// No description provided for @helpDashboardContinueExploreColdStart.
  ///
  /// In en, this message translates to:
  /// **'Recent works and entities you viewed will appear here once you start exploring.'**
  String get helpDashboardContinueExploreColdStart;

  /// No description provided for @helpDashboardContinueExploreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exploration history yet. Open a work or entity to see it here.'**
  String get helpDashboardContinueExploreEmpty;

  /// No description provided for @helpDashboardContinueExploreFallback.
  ///
  /// In en, this message translates to:
  /// **'Try exploring from the recently added works.'**
  String get helpDashboardContinueExploreFallback;

  /// No description provided for @actionPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get actionPrev;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @labelHasRecord.
  ///
  /// In en, this message translates to:
  /// **'Has Record'**
  String get labelHasRecord;

  /// No description provided for @tooltipVaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Vault Settings'**
  String get tooltipVaultSettings;

  /// No description provided for @labelDashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get labelDashboardQuickActions;

  /// No description provided for @descDashboardSearchWorks.
  ///
  /// In en, this message translates to:
  /// **'Find works and entities in the vault and catalog.'**
  String get descDashboardSearchWorks;

  /// No description provided for @descDashboardExploreEntities.
  ///
  /// In en, this message translates to:
  /// **'View registered person entities in a gallery.'**
  String get descDashboardExploreEntities;

  /// No description provided for @descDashboardConnectionMap.
  ///
  /// In en, this message translates to:
  /// **'View the relationships of works and entities linked via [[wiki]].'**
  String get descDashboardConnectionMap;

  /// No description provided for @descDashboardAllBrowse.
  ///
  /// In en, this message translates to:
  /// **'Explore library works in a grid view.'**
  String get descDashboardAllBrowse;

  /// No description provided for @descDashboardWrite.
  ///
  /// In en, this message translates to:
  /// **'Check chronological logs in the timeline and journal.'**
  String get descDashboardWrite;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @labelNowViewing.
  ///
  /// In en, this message translates to:
  /// **'Now Viewing'**
  String get labelNowViewing;

  /// No description provided for @actionWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get actionWrite;

  /// No description provided for @hintMemoBar.
  ///
  /// In en, this message translates to:
  /// **'Add a memo...'**
  String get hintMemoBar;

  /// No description provided for @actionEditMemo.
  ///
  /// In en, this message translates to:
  /// **'Edit Memo'**
  String get actionEditMemo;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @confirmDeleteMemo.
  ///
  /// In en, this message translates to:
  /// **'Delete this memo?'**
  String get confirmDeleteMemo;

  /// No description provided for @helpJournalConnectVault.
  ///
  /// In en, this message translates to:
  /// **'Connect a vault to view memos.'**
  String get helpJournalConnectVault;

  /// No description provided for @helpJournalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memos yet.'**
  String get helpJournalEmpty;

  /// No description provided for @actionWriteFirstMemo.
  ///
  /// In en, this message translates to:
  /// **'Write First Memo'**
  String get actionWriteFirstMemo;

  /// No description provided for @countMemos.
  ///
  /// In en, this message translates to:
  /// **'Memos ({count})'**
  String countMemos(int count);

  /// No description provided for @tooltipNewMemo.
  ///
  /// In en, this message translates to:
  /// **'New Memo'**
  String get tooltipNewMemo;

  /// No description provided for @tooltipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tooltipRefresh;

  /// No description provided for @actionEditTimeline.
  ///
  /// In en, this message translates to:
  /// **'Edit Timeline'**
  String get actionEditTimeline;

  /// No description provided for @confirmDeleteTimeline.
  ///
  /// In en, this message translates to:
  /// **'Delete this timeline record?'**
  String get confirmDeleteTimeline;

  /// No description provided for @helpTimelineConnectVault.
  ///
  /// In en, this message translates to:
  /// **'Connect a vault to view the timeline.'**
  String get helpTimelineConnectVault;

  /// No description provided for @helpTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timeline records yet.'**
  String get helpTimelineEmpty;

  /// No description provided for @actionWriteFirstRecord.
  ///
  /// In en, this message translates to:
  /// **'Write First Record'**
  String get actionWriteFirstRecord;

  /// No description provided for @countTimelineRecords.
  ///
  /// In en, this message translates to:
  /// **'Timeline ({count})'**
  String countTimelineRecords(int count);

  /// No description provided for @tooltipNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record'**
  String get tooltipNewRecord;

  /// No description provided for @helpEntityJournalConnectVault.
  ///
  /// In en, this message translates to:
  /// **'Connect a vault to view the entity journal.'**
  String get helpEntityJournalConnectVault;

  /// No description provided for @helpEntityJournalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entity journal entries yet.'**
  String get helpEntityJournalEmpty;

  /// No description provided for @helpEntityJournalTip.
  ///
  /// In en, this message translates to:
  /// **'Archive Person, Concept, or Event via Fusion → Add Direct.'**
  String get helpEntityJournalTip;

  /// No description provided for @countEntityJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'Entity Journal ({count})'**
  String countEntityJournalEntries(int count);

  /// No description provided for @errorConnectVaultFirst.
  ///
  /// In en, this message translates to:
  /// **'Please connect the vault first.'**
  String get errorConnectVaultFirst;

  /// No description provided for @errorEntityNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find \"{id}\".'**
  String errorEntityNotFound(String id);

  /// No description provided for @errorVaultConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect vault: {error}'**
  String errorVaultConnectionFailed(String error);

  /// No description provided for @successEntityArchived.
  ///
  /// In en, this message translates to:
  /// **'{badge} \"{title}\" added to archive · Check in Logs → Entity'**
  String successEntityArchived(String badge, String title);

  /// No description provided for @successEntityRegisteredOnly.
  ///
  /// In en, this message translates to:
  /// **'{badge} \"{title}\" registered name only · Can archive in Fusion'**
  String successEntityRegisteredOnly(String badge, String title);

  /// No description provided for @successArchivedWork.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has been archived.'**
  String successArchivedWork(String title);

  /// No description provided for @actionAddCustomSection.
  ///
  /// In en, this message translates to:
  /// **'Add custom section'**
  String get actionAddCustomSection;

  /// No description provided for @actionAddCustomWithType.
  ///
  /// In en, this message translates to:
  /// **'Add directly (choose type)'**
  String get actionAddCustomWithType;

  /// No description provided for @actionAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get actionAddToLibrary;

  /// No description provided for @actionApplyManual.
  ///
  /// In en, this message translates to:
  /// **'Apply manually'**
  String get actionApplyManual;

  /// No description provided for @actionApplyThisImage.
  ///
  /// In en, this message translates to:
  /// **'Apply this image'**
  String get actionApplyThisImage;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get actionKeep;

  /// No description provided for @actionOpenGoogleImageSearch.
  ///
  /// In en, this message translates to:
  /// **'Open Google Image Search'**
  String get actionOpenGoogleImageSearch;

  /// No description provided for @actionOpenPinterestSearch.
  ///
  /// In en, this message translates to:
  /// **'Open Pinterest Search'**
  String get actionOpenPinterestSearch;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @actionProposeToGlobalRegistry.
  ///
  /// In en, this message translates to:
  /// **'Propose to global registry'**
  String get actionProposeToGlobalRegistry;

  /// No description provided for @actionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// No description provided for @actionReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get actionReload;

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

  /// No description provided for @actionReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get actionReplaceAll;

  /// No description provided for @actionSelectLocalImage.
  ///
  /// In en, this message translates to:
  /// **'Select local image'**
  String get actionSelectLocalImage;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @addConcept.
  ///
  /// In en, this message translates to:
  /// **'Add concept'**
  String get addConcept;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @addOrganization.
  ///
  /// In en, this message translates to:
  /// **'Add organization'**
  String get addOrganization;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @addPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// No description provided for @linkEntity.
  ///
  /// In en, this message translates to:
  /// **'Link entity'**
  String get linkEntity;

  /// No description provided for @addWork.
  ///
  /// In en, this message translates to:
  /// **'Add work'**
  String get addWork;

  /// No description provided for @breadcrumbLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get breadcrumbLibrary;

  /// No description provided for @breadcrumbWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get breadcrumbWork;

  /// No description provided for @clipboardImageDetected.
  ///
  /// In en, this message translates to:
  /// **'Clipboard image detected'**
  String get clipboardImageDetected;

  /// No description provided for @errorBrowserLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open browser: {error}'**
  String errorBrowserLaunchFailed(String error);

  /// No description provided for @errorCannotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Cannot open browser.'**
  String get errorCannotOpenBrowser;

  /// No description provided for @externalFileChanged.
  ///
  /// In en, this message translates to:
  /// **'External file changed'**
  String get externalFileChanged;

  /// No description provided for @globalRegistryLabel.
  ///
  /// In en, this message translates to:
  /// **'Global registry'**
  String get globalRegistryLabel;

  /// No description provided for @helpFullFileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit the full markdown file.'**
  String get helpFullFileEdit;

  /// No description provided for @helpMarkdownBodyEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit the markdown body.'**
  String get helpMarkdownBodyEdit;

  /// No description provided for @helpSectionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit this section.'**
  String get helpSectionEdit;

  /// No description provided for @hintEnterDirectImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a direct image URL'**
  String get hintEnterDirectImageUrl;

  /// No description provided for @hintEnterPosterSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter a poster search query'**
  String get hintEnterPosterSearchQuery;

  /// No description provided for @hintFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get hintFind;

  /// No description provided for @hintHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hintHidden;

  /// No description provided for @hintNotArchived.
  ///
  /// In en, this message translates to:
  /// **'Not archived'**
  String get hintNotArchived;

  /// No description provided for @hintReplaceText.
  ///
  /// In en, this message translates to:
  /// **'Replace text'**
  String get hintReplaceText;

  /// No description provided for @hintSearchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search works, people, events, places, and concepts...'**
  String get hintSearchEverything;

  /// No description provided for @hintSearchExplain.
  ///
  /// In en, this message translates to:
  /// **'Search your archive and the starter catalog.'**
  String get hintSearchExplain;

  /// No description provided for @hintSearchWorkFromRegistry.
  ///
  /// In en, this message translates to:
  /// **'Search works from the registry'**
  String get hintSearchWorkFromRegistry;

  /// No description provided for @hintSiblingTracked.
  ///
  /// In en, this message translates to:
  /// **'A related entry is already tracked'**
  String get hintSiblingTracked;

  /// No description provided for @hintWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Work title'**
  String get hintWorkTitle;

  /// No description provided for @imageCorrectionGuideSteps.
  ///
  /// In en, this message translates to:
  /// **'Copy an image, paste a URL, or choose a local file.'**
  String get imageCorrectionGuideSteps;

  /// No description provided for @imageCorrectionGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Image correction guide'**
  String get imageCorrectionGuideTitle;

  /// No description provided for @incomingLinkCount.
  ///
  /// In en, this message translates to:
  /// **'{count} incoming record(s)'**
  String incomingLinkCount(int count);

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid image URL'**
  String get invalidImageUrl;

  /// No description provided for @labelRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get labelRegistry;

  /// No description provided for @labelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get labelWarning;

  /// No description provided for @myArchiveLabel.
  ///
  /// In en, this message translates to:
  /// **'My archive'**
  String get myArchiveLabel;

  /// No description provided for @myRegistrationLabel.
  ///
  /// In en, this message translates to:
  /// **'My registration'**
  String get myRegistrationLabel;

  /// No description provided for @noLinksYet.
  ///
  /// In en, this message translates to:
  /// **'No {title} links yet.'**
  String noLinksYet(String title);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// No description provided for @posterSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Poster search query'**
  String get posterSearchQuery;

  /// No description provided for @posterSuffix.
  ///
  /// In en, this message translates to:
  /// **'poster'**
  String get posterSuffix;

  /// No description provided for @recordBody.
  ///
  /// In en, this message translates to:
  /// **'Record body'**
  String get recordBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @sectionCast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get sectionCast;

  /// No description provided for @sectionConnectedConcepts.
  ///
  /// In en, this message translates to:
  /// **'Connected concepts'**
  String get sectionConnectedConcepts;

  /// No description provided for @sectionConnectedEvents.
  ///
  /// In en, this message translates to:
  /// **'Connected events'**
  String get sectionConnectedEvents;

  /// No description provided for @sectionConnectedOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Connected organizations'**
  String get sectionConnectedOrganizations;

  /// No description provided for @sectionConnectedPersons.
  ///
  /// In en, this message translates to:
  /// **'Connected people'**
  String get sectionConnectedPersons;

  /// No description provided for @sectionConnectedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Connected places'**
  String get sectionConnectedPlaces;

  /// No description provided for @sectionConnectedWorks.
  ///
  /// In en, this message translates to:
  /// **'Connected works'**
  String get sectionConnectedWorks;

  /// No description provided for @sectionGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get sectionGallery;

  /// No description provided for @sectionGlobalRegistryEntity.
  ///
  /// In en, this message translates to:
  /// **'Global registry entities'**
  String get sectionGlobalRegistryEntity;

  /// No description provided for @sectionGlobalRegistryWork.
  ///
  /// In en, this message translates to:
  /// **'Global registry works'**
  String get sectionGlobalRegistryWork;

  /// No description provided for @sectionMainCharacters.
  ///
  /// In en, this message translates to:
  /// **'Main characters'**
  String get sectionMainCharacters;

  /// No description provided for @sectionMemo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get sectionMemo;

  /// No description provided for @sectionMyArchiveEntity.
  ///
  /// In en, this message translates to:
  /// **'My archive entities'**
  String get sectionMyArchiveEntity;

  /// No description provided for @sectionMyArchiveWork.
  ///
  /// In en, this message translates to:
  /// **'My archive works'**
  String get sectionMyArchiveWork;

  /// No description provided for @sectionMyArchiveWorkRegisteredOnly.
  ///
  /// In en, this message translates to:
  /// **'Registered works only'**
  String get sectionMyArchiveWorkRegisteredOnly;

  /// No description provided for @sectionNotArchived.
  ///
  /// In en, this message translates to:
  /// **'Not archived'**
  String get sectionNotArchived;

  /// No description provided for @sectionQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get sectionQuotes;

  /// No description provided for @sectionSynopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get sectionSynopsis;

  /// No description provided for @tabBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get tabBody;

  /// No description provided for @tabConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get tabConnection;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @tabRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get tabRecord;

  /// No description provided for @tabView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get tabView;

  /// No description provided for @tooltipBlockquote.
  ///
  /// In en, this message translates to:
  /// **'Blockquote'**
  String get tooltipBlockquote;

  /// No description provided for @tooltipBold.
  ///
  /// In en, this message translates to:
  /// **'Bold (Ctrl+B)'**
  String get tooltipBold;

  /// No description provided for @tooltipBulletedList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get tooltipBulletedList;

  /// No description provided for @tooltipFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get tooltipFind;

  /// No description provided for @tooltipH1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get tooltipH1;

  /// No description provided for @tooltipH2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get tooltipH2;

  /// No description provided for @tooltipH3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get tooltipH3;

  /// No description provided for @tooltipImageVaultRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect a vault to insert images'**
  String get tooltipImageVaultRequired;

  /// No description provided for @tooltipInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get tooltipInlineCode;

  /// No description provided for @tooltipInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get tooltipInsertImage;

  /// No description provided for @tooltipInsertSection.
  ///
  /// In en, this message translates to:
  /// **'Insert section'**
  String get tooltipInsertSection;

  /// No description provided for @tooltipItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic (Ctrl+I)'**
  String get tooltipItalic;

  /// No description provided for @tooltipLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get tooltipLink;

  /// No description provided for @tooltipLinkEntity.
  ///
  /// In en, this message translates to:
  /// **'Link entity'**
  String get tooltipLinkEntity;

  /// No description provided for @tooltipNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get tooltipNumberedList;

  /// No description provided for @tooltipSmartPaste.
  ///
  /// In en, this message translates to:
  /// **'Smart paste'**
  String get tooltipSmartPaste;

  /// No description provided for @tooltipStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get tooltipStrikethrough;

  /// No description provided for @tooltipTableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of contents'**
  String get tooltipTableOfContents;

  /// No description provided for @waitingForClipboardImage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for clipboard image...'**
  String get waitingForClipboardImage;

  /// No description provided for @webImageSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive poster image correction'**
  String get webImageSearchTitle;

  /// No description provided for @sectionHofTitle.
  ///
  /// In en, this message translates to:
  /// **'S-Tier Life Favorites (Hall of Fame)'**
  String get sectionHofTitle;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Catalog (Registry + Archive)'**
  String get catalogTitle;

  /// No description provided for @personalLibraryCountDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} archived work(s)'**
  String personalLibraryCountDesc(int count);

  /// No description provided for @catalogMediaSortDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} shown · sorted by media · archived works appear as cards'**
  String catalogMediaSortDesc(int count);

  /// No description provided for @catalogGeneralDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} shown · archive-first items are available in the sidebar library'**
  String catalogGeneralDesc(int count);

  /// No description provided for @worksCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'({count} works)'**
  String worksCountSuffix(int count);

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistTitle;

  /// No description provided for @watchlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Works {displayName} marked to watch later.'**
  String watchlistDescription(String displayName);

  /// No description provided for @watchlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No watchlist items yet.'**
  String get watchlistEmptyTitle;

  /// No description provided for @watchlistEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Add a new work or set its personal status to Watchlist.'**
  String get watchlistEmptyHelp;

  /// No description provided for @yearlyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly Library'**
  String get yearlyLibraryTitle;

  /// No description provided for @yearlyLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse your library by release year.'**
  String get yearlyLibraryDescription;

  /// No description provided for @yearlyHeader.
  ///
  /// In en, this message translates to:
  /// **'{year}'**
  String yearlyHeader(int year);

  /// No description provided for @yearlyNoYear.
  ///
  /// In en, this message translates to:
  /// **'Year unknown'**
  String get yearlyNoYear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
