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
  /// **'View all'**
  String get sidebarViewAll;

  /// No description provided for @sidebarNoCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections'**
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
  /// **'Save MD'**
  String get actionSaveMd;
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
