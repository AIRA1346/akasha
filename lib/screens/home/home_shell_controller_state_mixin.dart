import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/personal_library_membership_service.dart';
import 'app_destination.dart';
import 'home_shell_controller_base.dart';
import 'preview_frame.dart';

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

  PreviewTarget get previewTarget => preview.previewTarget;
  bool get hasOpenPreview => preview.hasOpenPreview;
  bool get canPopPreview => preview.canPopPreview;

  List<AkashaItem> get items => vault.items;
  String get displayName => vault.displayName;
  bool get autoArchiveRegistry => vault.autoArchiveRegistry;

  bool get isCatalogLoading => catalog.isCatalogLoading;
  bool get isCatalogLoadingMore => catalog.isCatalogLoadingMore;
  int get catalogBrowseOffset => catalog.catalogBrowseOffset;
  int get catalogTotalEntries => catalog.catalogTotalEntries;
  int get catalogContributionCount => catalog.catalogContributionCount;
  bool get catalogUsesWindowedPrefetch => catalog.catalogUsesWindowedPrefetch;
  bool get catalogHasMore => catalog.catalogHasMore;
  int get catalogLoadedThrough => catalog.catalogLoadedThrough;

  bool get isSidebarOpen => navigation.isSidebarOpen;
  AppDestination get currentDestination => navigation.currentDestination;
  int get timelineReloadToken => navigation.timelineReloadToken;
  bool get isCuratedLibraryActive => navigation.isCuratedLibraryActive;
  bool get canAddToLibrary => browse.canAddToLibrary;

  PersonalLibraryMembershipService get libraryMembership =>
      browse.libraryMembership;

  RecordLinkPort get linkIndex => vault.linkIndex;
  int get linkIndexRevision => vault.linkIndexRevision;

  List<BrowseCard> get filteredBrowseCards => browse.filteredBrowseCards;
  List<BrowseCard> get personalBrowseCards => browse.personalBrowseCards;
}
