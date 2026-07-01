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
  String get sidebarViewAll => 'View All';

  @override
  String get sidebarNoCollections => 'No Collections';

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
  String get actionSaveMd => 'Save md';

  @override
  String get mediaCategoryManga => 'Manga';

  @override
  String get mediaCategoryWebtoon => 'Webtoon';

  @override
  String get mediaCategoryAnimation => 'Animation';

  @override
  String get mediaCategoryGame => 'Game';

  @override
  String get mediaCategoryBook => 'Book/Novel/Light Novel';

  @override
  String get mediaCategoryMovie => 'Movie';

  @override
  String get mediaCategoryDrama => 'Drama';

  @override
  String get statusContentWorkSerializing => 'Serializing';

  @override
  String get statusContentWorkHiatus => 'Hiatus';

  @override
  String get statusContentWorkCompleted => 'Completed';

  @override
  String get statusContentMyNotStarted => 'Plan to Watch';

  @override
  String get statusContentMyWatching => 'Watching';

  @override
  String get statusContentMyFinished => 'Finished';

  @override
  String get statusContentMyDropped => 'Dropped';

  @override
  String get statusGameWorkReleased => 'Released';

  @override
  String get statusGameWorkEarlyAccess => 'Early Access';

  @override
  String get statusGameWorkUpcoming => 'Upcoming';

  @override
  String get statusGameMyBacklog => 'Backlog';

  @override
  String get statusGameMyPlaying => 'Playing';

  @override
  String get statusGameMyCleared => 'Cleared';

  @override
  String get statusGameMyAbandoned => 'Abandoned';

  @override
  String get sortCriteriaManual => 'Manual Order';

  @override
  String get sortCriteriaTitle => 'By Name';

  @override
  String get sortCriteriaRating => 'Highest Rating';

  @override
  String get sortCriteriaRecentlyAdded => 'Recently Added';

  @override
  String get sortCriteriaYear => 'Release Year';

  @override
  String get addWorkDialogTitle => 'New Work (Add to Archive)';

  @override
  String get registryWorkSearch => 'Search Global Catalog';

  @override
  String get labelTitle => 'Title';

  @override
  String get labelCreator => 'Creator / Studio';

  @override
  String get labelReleaseYear => 'Release Year';

  @override
  String get posterImageLabel => 'Poster Image (Web URL or Local File)';

  @override
  String get posterUrlHint => 'Enter https://... or local path';

  @override
  String get tooltipPickLocalImage => 'Select Local Image File';

  @override
  String get tooltipWebImageSearch => 'Search Web Images';

  @override
  String get myRating => 'My Rating';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelWorkStatus => 'Work Status';

  @override
  String get labelMyStatus => 'My Status';

  @override
  String get actionRegister => 'Register';

  @override
  String get validationEnterTitle => 'Please enter a title.';

  @override
  String get catalogAddContributionTitle => 'Global Catalog — Suggest New Work';

  @override
  String get labelTitleRequired => 'Title *';

  @override
  String get labelPosterUrl => 'Poster URL (https)';

  @override
  String get tooltipImageSearch => 'Image Search';

  @override
  String get labelDescriptionBrief => 'Description (write briefly)';

  @override
  String get labelAnilistId => 'AniList ID (optional, numbers only)';

  @override
  String get labelProposalNote => 'Proposal Note (optional)';

  @override
  String get actionSaveProposal => 'Save Proposal';

  @override
  String get validationPosterHttpsOnly => 'Poster must be an https URL.';

  @override
  String get catalogContributionDisclaimer =>
      'Proposals are saved locally. They will be reflected in the global catalog after review, merge into akasha-db, and app sync.';

  @override
  String get catalogFixContributionTitle => 'Global Catalog — Suggest Fix';

  @override
  String get labelWhatIsWrong => 'What is wrong? *';

  @override
  String get hintWhatIsWrong => 'e.g. Poster image belongs to a different work';

  @override
  String get fixPosterUrl => 'Fix Poster URL';

  @override
  String get labelProposedPosterUrl => 'Proposed Poster URL';

  @override
  String get fixReleaseYear => 'Fix Release Year';

  @override
  String get labelProposedYear => 'Proposed Year';

  @override
  String get fixTitle => 'Fix Title';

  @override
  String get labelProposedTitle => 'Proposed Title';

  @override
  String get fixCreator => 'Fix Creator / Studio';

  @override
  String get labelProposedCreator => 'Proposed Creator / Studio';

  @override
  String get labelAdditionalNote => 'Additional Note';

  @override
  String get validationEnterIssue => 'Please describe the issue.';

  @override
  String get validationSelectFixField => 'Please select a field to fix.';

  @override
  String get validationPosterHttpsRequired => 'Poster must be an https URL.';

  @override
  String get validationEnterYearNumber => 'Please enter the year as a number.';

  @override
  String get clipboardImportTitle => '🤖 AI Markdown Import';

  @override
  String get clipboardImportDescription =>
      'Paste AI-generated markdown text here. It will be parsed and added to your work list.';

  @override
  String get untitledWork => 'Untitled Work';

  @override
  String clipboardImportAlreadyExists(String title) {
    return '\"$title\" is already in the archive.';
  }

  @override
  String clipboardImportAdded(String title, String workId) {
    return '\"$title\" added (work_id: $workId)';
  }

  @override
  String clipboardImportParseFailed(String error) {
    return 'Parsing failed: $error';
  }

  @override
  String get actionParseAndImport => 'Parse & Import';

  @override
  String get noWorksInCatalogVault => 'No works in catalog or vault.';

  @override
  String get labelSelectWork => 'Select Work';

  @override
  String get optionNone => 'None';

  @override
  String get createCastFromWork => 'Create Cast from Selected Work';

  @override
  String get labelCollectionName => 'Collection Name';

  @override
  String get labelMode => 'Mode';

  @override
  String get modeFilter => 'Filter (tags · works · kind)';

  @override
  String get modeCurated => 'Curated (manual selection)';

  @override
  String get collectionAddTitle => 'Add Collection';

  @override
  String get collectionEditTitle => 'Collection Settings';

  @override
  String get noEntitiesInCatalog =>
      'No Person, Concept, or other entities in catalog.';

  @override
  String selectedCountReorderHint(int count) {
    return '$count selected · reorder in gallery';
  }

  @override
  String get deleteCollectionTitle => 'Delete Collection';

  @override
  String get deleteCollectionConfirm =>
      'Delete this collection? Entity data will be preserved.';

  @override
  String get actionDelete => 'Delete';

  @override
  String get presetAvailabilityNote =>
      'Only enabled when the work exists in vault or catalog.';

  @override
  String get customCreate => 'Create Manually';

  @override
  String get customCreateDescription =>
      'Tag-based · Work-based · Mixed — configure below, then tap \"Add\"';

  @override
  String get tabExistingLink => 'Existing Links';

  @override
  String get tabCreateNew => 'Create New';

  @override
  String get hintSearchNameAlias => 'Search by name or alias';

  @override
  String get noEntitiesAvailable => 'No entities to link.';

  @override
  String noMatchingEntity(String query) {
    return 'No items matching \"$query\".';
  }

  @override
  String get sectionRelatedToWork => 'Related to this Work';

  @override
  String get sectionSearchResults => 'Search Results';

  @override
  String createEntityAndLink(String typeLabel) {
    return 'Register a new $typeLabel not in the catalog and link it to this work.';
  }

  @override
  String get useSearchQueryAsName => 'Use search term as name';

  @override
  String createNewEntityType(String typeLabel) {
    return 'Create New $typeLabel';
  }

  @override
  String get subtitleRecommendations =>
      'Recommendations · Person · Event · Concept · Place · Org';

  @override
  String get subtitleSeedAvailable =>
      'Not in your catalog · Can link from seed catalog';

  @override
  String get subtitleCatalog =>
      'Catalog · Person · Event · Concept · Place · Org';

  @override
  String get journalQuickCaptureTitle => 'Quick Memo';

  @override
  String get labelBody => 'Body';

  @override
  String get hintJournalBody => 'Ideas, memos, thoughts…';

  @override
  String get labelTitleOptional => 'Title (optional)';

  @override
  String get hintTitleAutoFill => 'Leave empty to use beginning of body';

  @override
  String get personalLibraryAddTitle => 'Add Personal Library';

  @override
  String get labelLibraryName => 'Library Name';

  @override
  String get hintLibraryName =>
      'e.g. All-time Favorites, Reading Backlog 2026…';

  @override
  String get helperLibraryCreate =>
      'Add works after creating. Filters can be adjusted in settings.';

  @override
  String get personalLibraryEditTitle => 'Personal Library Settings';

  @override
  String get hintLibraryNameEdit => 'e.g. All-time Favorites, Completed List…';

  @override
  String get helperMasterArchiveReadonly =>
      'The master_archive name cannot be changed.';

  @override
  String get helperCuratedMode =>
      'Only included works are shown. Filters narrow further.';

  @override
  String get helperFilterMode =>
      'Only archived vault works are shown via filters.';

  @override
  String get addWorkSearch => 'Add Work (Search)';

  @override
  String includedWorksCount(int count) {
    return 'Included Works ($count)';
  }

  @override
  String get noIncludedWorks => 'No works included yet.';

  @override
  String cleanOrphanIds(int count) {
    return 'Clean Orphan IDs ($count)';
  }

  @override
  String get labelCategoryFilter => 'Category Filter (multi-select)';

  @override
  String get labelWorkStatusFilter => 'Work Status Filter (multi-select)';

  @override
  String get labelMyStatusFilter => 'My Status Filter (multi-select)';

  @override
  String get promptTemplateTitle => 'AI Prompt Template';

  @override
  String get promptTemplateDescription =>
      'Provide this template to an AI to easily get properly formatted markdown.';

  @override
  String get templateCopiedToClipboard => 'Template copied to clipboard.';

  @override
  String get registrySyncTitle => 'Global Catalog Sync';

  @override
  String lastSyncTime(String time) {
    return 'Last sync: $time';
  }

  @override
  String get actionSyncNow => 'Sync Now';

  @override
  String get labelCustomDbUrl => 'Custom Catalog DB Base URL';

  @override
  String get customDbUrlDescription =>
      'Downloads manifest.json, search_index.json, and shards/ files from this address.';

  @override
  String get syncUrlChanged => 'Sync URL has been updated.';

  @override
  String get actionSaveUrl => 'Save URL';

  @override
  String get timelineQuickCaptureTitle => 'Timeline Entry';

  @override
  String get hintTimelineBody => 'Today\'s thoughts, diary, ideas…';

  @override
  String get labelWorkLinkOptional => 'Link Work (optional)';

  @override
  String get optionNoLink => 'No Link';

  @override
  String get timelineSaveLocationInfo => 'Saved to vault/timeline/.';

  @override
  String get workLinkPickerTitle => 'Add Work';

  @override
  String get hintSearchTitleCreatorId => 'Search by title, creator, or work_id';

  @override
  String get workLinkPickerDescription =>
      'Link library works to the document as [[links]].';

  @override
  String get noOtherWorksToLink => 'No other works to link.';

  @override
  String noMatchingWork(String query) {
    return 'No works matching \"$query\".';
  }

  @override
  String catalogContributionsTitle(int count) {
    return 'Catalog Proposals ($count)';
  }

  @override
  String get noSavedProposals => 'No saved proposals.';

  @override
  String get suggestNewWork => 'Suggest New Work';

  @override
  String get actionCopyJson => 'Copy JSON';

  @override
  String get actionOpenGithubIssue => 'Open GitHub Issue';

  @override
  String get actionCopyAllJson => 'Copy All JSON';

  @override
  String get proposalJsonCopied => 'Proposal JSON copied to clipboard.';

  @override
  String jsonCopiedWithFile(String path) {
    return 'JSON copied · File: $path';
  }

  @override
  String jsonCopiedFileFailed(String error) {
    return 'JSON copied (file save failed: $error)';
  }

  @override
  String get deleteUnsavedWarning => 'Unsaved changes will also be lost.';

  @override
  String get detailDeleteTitle => 'Delete Work';

  @override
  String detailDeleteConfirmVault(String title, String unsavedNote) {
    return 'Delete \"$title\" from the archive?\nThe local vault .md file will be permanently deleted.$unsavedNote\nIt won\'t disappear from browse/catalog lists, and auto-archiving may recreate the .md.';
  }

  @override
  String detailDeleteConfirmNoVault(String title, String unsavedNote) {
    return 'Remove \"$title\" from the list?\n(Demo mode — .md files will be deleted when vault is connected)$unsavedNote';
  }

  @override
  String get workbenchCloseTabDialogTitle => 'Unsaved Changes';

  @override
  String get workbenchCloseTabDialogMessage =>
      'You have unsaved changes. Do you want to close without saving?';

  @override
  String get workbenchCloseTabDialogSaveAndClose => 'Save & Close';

  @override
  String get workbenchCloseTabDialogDiscard => 'Discard';

  @override
  String get workbenchIncomingLinksRefresh => 'Refresh Incoming Links';

  @override
  String get workbenchBreadcrumbLibrary => 'Library';

  @override
  String get workbenchBreadcrumbWork => 'Work';

  @override
  String get workbenchTabConnections => 'Connections';

  @override
  String get workbenchTabDetails => 'Info';

  @override
  String get workbenchTabType => 'Type';

  @override
  String get workbenchTabConnectionCount => 'Connections Count';

  @override
  String get workbenchTabAliases => 'Aliases';

  @override
  String get workbenchTabStoragePath => 'Storage Path';

  @override
  String get helpWorkbenchConnectionExplain =>
      'Use Add in each section to connect entities. People go into cast slots; other entities are inserted as [[links]] in the journal body.';

  @override
  String get helpEntityConnectionExplain =>
      'Use Add in each section to connect records. [[links]] are inserted into the journal body.';

  @override
  String get workbenchCastSectionTitle => '👥 Cast';

  @override
  String get workbenchQuotesSectionTitle => '🎬 Moments & Quotes';

  @override
  String get workbenchSynopsisSectionTitle => '📋 Synopsis';

  @override
  String get workbenchGallerySectionTitle => '🖼 Gallery';

  @override
  String get workbenchMemoSectionTitle => '📝 Notes';

  @override
  String get workbenchEditorAddSection => 'Insert Section';

  @override
  String get workbenchEditorAddSectionTitle => 'Add Section';

  @override
  String get workbenchEditorFind => 'Find';

  @override
  String get workbenchEditorReplace => 'Replace';

  @override
  String get workbenchEditorNext => 'Next';

  @override
  String get workbenchEditorPrev => 'Prev';

  @override
  String get sidebarRecent => 'Recent';

  @override
  String get labelDashboardSearchWorks => 'Search Works';

  @override
  String get labelDashboardExploreEntities => 'Explore Entities';

  @override
  String get labelDashboardConnectionMap => 'Connection Map';

  @override
  String get labelDashboardAllBrowse => 'Browse All';

  @override
  String get labelDashboardWrite => 'Write';

  @override
  String get akashaPromptTemplate =>
      'You are a subculture (manga, game, anime, book) archiving expert.\nPlease write the requested work information in a markdown document, including the YAML Front-Matter format below.\n\n---\nwork_id: \"\" (Leave empty for AKASHA to auto-match or assign a custom ID)\ntitle: \"Exact Title of the Work\"\ncategory: manga | game | animation | book | movie | drama (Choose one)\ncreator: \"Creator / Studio / Director etc.\"\nrelease_year: Year of release or serialization start (number only, e.g. 2011)\nrating: 5.0 (Float in range 0.0~5.0)\nwork_status: \"serializing\" | \"hiatus\" | \"completed\" (For game category: \"released\" | \"earlyAccess\" | \"upcoming\")\nmy_status: \"notStarted\" | \"watching\" | \"finished\" | \"dropped\" (For game category: \"backlog\" | \"playing\" | \"cleared\" | \"abandoned\")\nis_hall_of_fame: true | false (Is all-time favorite)\ntags: [tag1, tag2] (e.g. [youth, touching, music])\nposter: \"\" (Leave empty)\nadded_at: \"Current date & time (ISO 8601, e.g. 2026-06-05T19:00:00)\"\n---\n\n# 👥 Cast\n\n# 🎬 Moments & Quotes\n> \"Moment description or quote\" — Character name / Context description\n\n# 📋 Synopsis\n\n# 🖼 Gallery\n\n# 📝 Notes\n';

  @override
  String get labelTags => 'Tags';

  @override
  String get recordKindTimeline => 'Timeline';

  @override
  String get recordKindJournal => 'Memo';

  @override
  String get recordKindWorkJournal => 'Work Journal';

  @override
  String get recordKindEntityJournal => 'Entity Journal';

  @override
  String get recordKindFreeformJournal => 'Freeform Journal';

  @override
  String connectedRecordsCount(int count) {
    return 'Connected Records ($count)';
  }

  @override
  String titleUpdateNeededCount(int count) {
    return 'Title update needed ($count)';
  }

  @override
  String sameDayRecordsCount(String date, int count) {
    return 'Same Day Records · $date ($count)';
  }

  @override
  String get actionCreateMd => 'Create md';

  @override
  String get actionSaveAndAddToLibrary => 'Save & Add to Library';

  @override
  String workbenchCloseTabMessageWithTitle(String title) {
    return 'There are unsaved changes in \"$title\".';
  }

  @override
  String workbenchCloseTabMessageWithTitleNoSave(String title) {
    return 'There are unsaved changes in \"$title\".\nPlease select this tab first to save changes.';
  }

  @override
  String entityJournalDeleteConfirm(String title) {
    return 'Are you sure you want to delete the entity journal for \"$title\"?';
  }

  @override
  String get entityJournalPlaceholderBody => '(Awaiting record)';

  @override
  String entityJournalSaveSuccess(String title) {
    return 'Saved entity journal for \"$title\".';
  }

  @override
  String get errorVaultRequired => 'Please link the vault first.';

  @override
  String get errorEmptyBody => 'Please enter the body text.';

  @override
  String errorSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get errorNoMdFileToDelete => 'No md file found to delete.';

  @override
  String get errorCatalogRequired => 'Catalog connection is required.';

  @override
  String get helpWorkbenchCastEditorEmpty =>
      'Add members using \"Add Person\" on the right to display them as cards in the preview.';

  @override
  String get hintCastRole => 'Role (e.g. Protagonist)';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionAddImage => 'Add Image';

  @override
  String get helpWorkbenchGalleryEditorEmpty =>
      'Drag and drop images, or use paste/add to insert screenshots and collages.';

  @override
  String get hintQuotesEditor => 'Enter one quote per line.';

  @override
  String get errorAddImageVaultRequired =>
      'Adding images is available after connecting the Sanctum vault.';

  @override
  String get errorPasteVaultRequired =>
      'Pasting is available after connecting the Sanctum vault.';

  @override
  String get errorNoImageInClipboard => 'No image found in the clipboard.';

  @override
  String get hintSynopsisEditor =>
      'Write the plot, world setting, background, etc.';

  @override
  String get hintMemoEditor =>
      'Thoughts, reviews, notes. Use \"Add\" on the right to insert [[links]].';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navCollections => 'Collections';

  @override
  String get errorVaultRequiredToAddToLibrary =>
      'Please connect the vault first to add to the library.';

  @override
  String alreadyInLibrary(String name) {
    return 'Already in the library \"$name\".';
  }

  @override
  String addedToLibrary(String name) {
    return 'Added to the library \"$name\".';
  }

  @override
  String get actionView => 'View';

  @override
  String errorArchiveFailed(String error) {
    return 'Archive failed: $error';
  }

  @override
  String get successRegistryCacheCleared =>
      'Cleared registry cache and restored bundle dictionary.';

  @override
  String errorClearCacheFailed(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get labelDashboardContinueExplore => 'Continue Exploring';

  @override
  String get helpDashboardContinueExploreColdStart =>
      'Recent works and entities you viewed will appear here once you start exploring.';

  @override
  String get helpDashboardContinueExploreEmpty =>
      'No exploration history yet. Open a work or entity to see it here.';

  @override
  String get helpDashboardContinueExploreFallback =>
      'Try exploring from the recently added works.';

  @override
  String get actionPrev => 'Prev';

  @override
  String get actionNext => 'Next';

  @override
  String get labelHasRecord => 'Has Record';

  @override
  String get tooltipVaultSettings => 'Vault Settings';

  @override
  String get labelDashboardQuickActions => 'Quick Actions';

  @override
  String get descDashboardSearchWorks =>
      'Find works and entities in the vault and catalog.';

  @override
  String get descDashboardExploreEntities =>
      'View registered person entities in a gallery.';

  @override
  String get descDashboardConnectionMap =>
      'View the relationships of works and entities linked via [[wiki]].';

  @override
  String get descDashboardAllBrowse => 'Explore library works in a grid view.';

  @override
  String get descDashboardWrite =>
      'Check chronological logs in the timeline and journal.';

  @override
  String get actionClose => 'Close';

  @override
  String get labelNowViewing => 'Now Viewing';

  @override
  String get actionWrite => 'Write';

  @override
  String get hintMemoBar => 'Add a memo...';

  @override
  String get actionEditMemo => 'Edit Memo';

  @override
  String get actionEdit => 'Edit';

  @override
  String get confirmDeleteMemo => 'Delete this memo?';

  @override
  String get helpJournalConnectVault => 'Connect a vault to view memos.';

  @override
  String get helpJournalEmpty => 'No memos yet.';

  @override
  String get actionWriteFirstMemo => 'Write First Memo';

  @override
  String countMemos(int count) {
    return 'Memos ($count)';
  }

  @override
  String get tooltipNewMemo => 'New Memo';

  @override
  String get tooltipRefresh => 'Refresh';

  @override
  String get actionEditTimeline => 'Edit Timeline';

  @override
  String get confirmDeleteTimeline => 'Delete this timeline record?';

  @override
  String get helpTimelineConnectVault =>
      'Connect a vault to view the timeline.';

  @override
  String get helpTimelineEmpty => 'No timeline records yet.';

  @override
  String get actionWriteFirstRecord => 'Write First Record';

  @override
  String countTimelineRecords(int count) {
    return 'Timeline ($count)';
  }

  @override
  String get tooltipNewRecord => 'New Record';

  @override
  String get helpEntityJournalConnectVault =>
      'Connect a vault to view the entity journal.';

  @override
  String get helpEntityJournalEmpty => 'No entity journal entries yet.';

  @override
  String get helpEntityJournalTip =>
      'Archive Person, Concept, or Event via Fusion → Add Direct.';

  @override
  String countEntityJournalEntries(int count) {
    return 'Entity Journal ($count)';
  }

  @override
  String get errorConnectVaultFirst => 'Please connect the vault first.';

  @override
  String errorEntityNotFound(String id) {
    return 'Could not find \"$id\".';
  }

  @override
  String errorVaultConnectionFailed(String error) {
    return 'Failed to connect vault: $error';
  }

  @override
  String successEntityArchived(String badge, String title) {
    return '$badge \"$title\" added to archive · Check in Logs → Entity';
  }

  @override
  String successEntityRegisteredOnly(String badge, String title) {
    return '$badge \"$title\" registered name only · Can archive in Fusion';
  }

  @override
  String successArchivedWork(String title) {
    return '\"$title\" has been archived.';
  }

  @override
  String get actionAddCustomSection => 'Add custom section';

  @override
  String get actionAddCustomWithType => 'Add directly (choose type)';

  @override
  String get actionAddToLibrary => 'Add to library';

  @override
  String get actionApplyManual => 'Apply manually';

  @override
  String get actionApplyThisImage => 'Apply this image';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionKeep => 'Keep';

  @override
  String get actionOpenGoogleImageSearch => 'Open Google Image Search';

  @override
  String get actionOpenPinterestSearch => 'Open Pinterest Search';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionProposeToGlobalRegistry => 'Propose to global registry';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionReload => 'Reload';

  @override
  String get actionReplace => 'Replace';

  @override
  String get actionReplaceAll => 'Replace all';

  @override
  String get actionSelectLocalImage => 'Select local image';

  @override
  String get actionUndo => 'Undo';

  @override
  String get addConcept => 'Add concept';

  @override
  String get addEvent => 'Add event';

  @override
  String get addOrganization => 'Add organization';

  @override
  String get addPerson => 'Add person';

  @override
  String get addPlace => 'Add place';

  @override
  String get linkEntity => 'Link entity';

  @override
  String get addWork => 'Add work';

  @override
  String get breadcrumbLibrary => 'Library';

  @override
  String get breadcrumbWork => 'Work';

  @override
  String get clipboardImageDetected => 'Clipboard image detected';

  @override
  String errorBrowserLaunchFailed(String error) {
    return 'Failed to open browser: $error';
  }

  @override
  String get errorCannotOpenBrowser => 'Cannot open browser.';

  @override
  String get externalFileChanged => 'External file changed';

  @override
  String get globalRegistryLabel => 'Global registry';

  @override
  String get helpFullFileEdit => 'Edit the full markdown file.';

  @override
  String get helpMarkdownBodyEdit => 'Edit the markdown body.';

  @override
  String get helpSectionEdit => 'Edit this section.';

  @override
  String get hintEnterDirectImageUrl => 'Enter a direct image URL';

  @override
  String get hintEnterPosterSearchQuery => 'Enter a poster search query';

  @override
  String get hintFind => 'Find';

  @override
  String get hintHidden => 'Hidden';

  @override
  String get hintNotArchived => 'Not archived';

  @override
  String get hintReplaceText => 'Replace text';

  @override
  String get hintSearchEverything =>
      'Search works, people, events, places, and concepts...';

  @override
  String get hintSearchExplain =>
      'Search your archive and the starter catalog.';

  @override
  String get hintSearchWorkFromRegistry => 'Search works from the registry';

  @override
  String get hintSiblingTracked => 'A related entry is already tracked';

  @override
  String get hintWorkTitle => 'Work title';

  @override
  String get imageCorrectionGuideSteps =>
      'Copy an image, paste a URL, or choose a local file.';

  @override
  String get imageCorrectionGuideTitle => 'Image correction guide';

  @override
  String incomingLinkCount(int count) {
    return '$count incoming record(s)';
  }

  @override
  String get invalidImageUrl => 'Invalid image URL';

  @override
  String get labelRegistry => 'Registry';

  @override
  String get labelWarning => 'Warning';

  @override
  String get myArchiveLabel => 'My archive';

  @override
  String get myRegistrationLabel => 'My registration';

  @override
  String noLinksYet(String title) {
    return 'No $title links yet.';
  }

  @override
  String get noSearchResults => 'No search results';

  @override
  String get posterSearchQuery => 'Poster search query';

  @override
  String get posterSuffix => 'poster';

  @override
  String get recordBody => 'Record body';

  @override
  String get searchTitle => 'Search';

  @override
  String get sectionCast => 'Cast';

  @override
  String get sectionConnectedConcepts => 'Connected concepts';

  @override
  String get sectionConnectedEvents => 'Connected events';

  @override
  String get sectionConnectedOrganizations => 'Connected organizations';

  @override
  String get sectionConnectedPersons => 'Connected people';

  @override
  String get sectionConnectedPlaces => 'Connected places';

  @override
  String get sectionConnectedWorks => 'Connected works';

  @override
  String get sectionGallery => 'Gallery';

  @override
  String get sectionGlobalRegistryEntity => 'Global registry entities';

  @override
  String get sectionGlobalRegistryWork => 'Global registry works';

  @override
  String get sectionMainCharacters => 'Main characters';

  @override
  String get sectionMemo => 'Memo';

  @override
  String get sectionMyArchiveEntity => 'My archive entities';

  @override
  String get sectionMyArchiveWork => 'My archive works';

  @override
  String get sectionMyArchiveWorkRegisteredOnly => 'Registered works only';

  @override
  String get sectionNotArchived => 'Not archived';

  @override
  String get sectionQuotes => 'Quotes';

  @override
  String get sectionSynopsis => 'Synopsis';

  @override
  String get tabBody => 'Body';

  @override
  String get tabConnection => 'Connection';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabRecord => 'Record';

  @override
  String get tabView => 'View';

  @override
  String get tooltipBlockquote => 'Blockquote';

  @override
  String get tooltipBold => 'Bold (Ctrl+B)';

  @override
  String get tooltipBulletedList => 'Bulleted list';

  @override
  String get tooltipFind => 'Find';

  @override
  String get tooltipH1 => 'Heading 1';

  @override
  String get tooltipH2 => 'Heading 2';

  @override
  String get tooltipH3 => 'Heading 3';

  @override
  String get tooltipImageVaultRequired => 'Connect a vault to insert images';

  @override
  String get tooltipInlineCode => 'Inline code';

  @override
  String get tooltipInsertImage => 'Insert image';

  @override
  String get tooltipInsertSection => 'Insert section';

  @override
  String get tooltipItalic => 'Italic (Ctrl+I)';

  @override
  String get tooltipLink => 'Link';

  @override
  String get tooltipLinkEntity => 'Link entity';

  @override
  String get tooltipNumberedList => 'Numbered list';

  @override
  String get tooltipSmartPaste => 'Smart paste';

  @override
  String get tooltipStrikethrough => 'Strikethrough';

  @override
  String get tooltipTableOfContents => 'Table of contents';

  @override
  String get waitingForClipboardImage => 'Waiting for clipboard image...';

  @override
  String get webImageSearchTitle => 'Archive poster image correction';

  @override
  String get sectionHofTitle => 'S-Tier Life Favorites (Hall of Fame)';

  @override
  String get catalogTitle => 'Work Catalog (Registry + Archive)';

  @override
  String personalLibraryCountDesc(int count) {
    return '$count archived work(s)';
  }

  @override
  String catalogMediaSortDesc(int count) {
    return '$count shown · sorted by media · archived works appear as cards';
  }

  @override
  String catalogGeneralDesc(int count) {
    return '$count shown · archive-first items are available in the sidebar library';
  }

  @override
  String worksCountSuffix(int count) {
    return '($count works)';
  }

  @override
  String get watchlistTitle => 'Watchlist';

  @override
  String watchlistDescription(String displayName) {
    return 'Works $displayName marked to watch later.';
  }

  @override
  String get watchlistEmptyTitle => 'No watchlist items yet.';

  @override
  String get watchlistEmptyHelp =>
      'Add a new work or set its personal status to Watchlist.';

  @override
  String get yearlyLibraryTitle => 'Yearly Library';

  @override
  String get yearlyLibraryDescription => 'Browse your library by release year.';

  @override
  String yearlyHeader(int year) {
    return '$year';
  }

  @override
  String get yearlyNoYear => 'Year unknown';
}
