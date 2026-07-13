import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/personal_library_membership_service.dart';
import 'home_shell_controller_base.dart';

/// Home shell UI-facing state getters.
mixin HomeShellControllerStateMixin on HomeShellControllerBase {
  EntityAnchorType? get pendingWorkEntityLinkType =>
      preview.pendingWorkEntityLinkType;
  String? get pendingWorkEntityLinkWorkId =>
      preview.pendingWorkEntityLinkWorkId;
  LinkCandidate? get pendingWorkEntityLinkCandidate =>
      preview.pendingWorkEntityLinkCandidate;
  bool get pendingWorkLinkPick => preview.pendingWorkLinkPick;
  EntityAnchorType? get pendingEntityEntityLinkType =>
      preview.pendingEntityEntityLinkType;
  String? get pendingEntityLinkEntityId => preview.pendingEntityLinkEntityId;
  bool get pendingEntityWorkLinkPick => preview.pendingEntityWorkLinkPick;

  List<AkashaItem> get recentExploreItems => recentExplore.items;

  AkashaItem? get workPreviewItem => preview.workPreviewItem;
  UserCatalogEntity? get entityPreviewItem => preview.entityPreviewItem;
  bool get hasOpenPreview => preview.hasOpenPreview;
  bool get canPopPreview => preview.canPopPreview;

  List<AkashaItem> get items => vault.items;
  String get displayName => vault.displayName;
  bool get autoArchiveRegistry => vault.autoArchiveRegistry;

  bool get isSyncing => catalog.isSyncing;
  bool get isCatalogLoading => catalog.isCatalogLoading;
  bool get isCatalogLoadingMore => catalog.isCatalogLoadingMore;
  int get catalogBrowseOffset => catalog.catalogBrowseOffset;
  int get catalogTotalEntries => catalog.catalogTotalEntries;
  DateTime? get lastSyncTime => catalog.lastSyncTime;
  int get catalogContributionCount => catalog.catalogContributionCount;
  bool get catalogUsesWindowedPrefetch => catalog.catalogUsesWindowedPrefetch;
  bool get catalogHasMore => catalog.catalogHasMore;
  int get catalogLoadedThrough => catalog.catalogLoadedThrough;

  bool get isSidebarOpen => navigation.isSidebarOpen;
  int get timelineReloadToken => navigation.timelineReloadToken;
  bool get isPersonalLibraryMode => navigation.isPersonalLibraryMode;
  bool get isCollectibleCollectionMode =>
      navigation.isCollectibleCollectionMode;
  bool get isTimelineMode => navigation.isTimelineMode;
  bool get isRecordsMode => navigation.isRecordsMode;
  bool get isCuratedLibraryActive => navigation.isCuratedLibraryActive;
  bool get isHomeDashboardMode => navigation.isHomeDashboardMode;
  bool get isExploreBrowseMode => navigation.isExploreBrowseMode;
  bool get isKnowledgeGraphMode => navigation.isKnowledgeGraphMode;
  bool get isExploreModeActive => navigation.isExploreModeActive;
  bool get canAddToLibrary => browse.canAddToLibrary;

  PersonalLibraryMembershipService get libraryMembership =>
      browse.libraryMembership;

  RecordLinkPort get linkIndex => vault.linkIndex;
  int get linkIndexRevision => vault.linkIndexRevision;

  List<BrowseCard> get filteredBrowseCards => browse.filteredBrowseCards;
  List<BrowseCard> get personalBrowseCards => browse.personalBrowseCards;
}
