import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/browse_card.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/enums.dart';
import '../../../services/file_service.dart';
import '../home_browse_filter_controller.dart';
import '../home_personal_library_controller.dart';
import '../home_poster_card_factory.dart';
import '../views/personal_library_view.dart';
import 'home_navigation_coordinator.dart';
import '../home_registry_hide_actions.dart';
import 'home_shell_wiring.dart';
import 'home_workbench_coordinator.dart';
import '../../../services/personal_library_membership_service.dart';

/// Browse 필터·카드·DnD (E2-4).
class HomeBrowseCoordinator {
  HomeBrowseCoordinator({
    required this.hostContext,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.rebuild,
    required this.wiring,
    required this.navigation,
    required this.workbenchCoord,
    required this.filterCtrl,
    required this.personalLibCtrl,
    required this.getItems,
    required this.prefetchRegistry,
    required this.wrapSetState,
  });

  final BuildContext Function() hostContext;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final void Function() rebuild;
  final HomeShellWiring wiring;
  final HomeNavigationCoordinator navigation;
  final HomeWorkbenchCoordinator workbenchCoord;
  final HomeBrowseFilterController filterCtrl;
  final HomePersonalLibraryController personalLibCtrl;
  final List<AkashaItem> Function() getItems;
  final Future<void> Function() prefetchRegistry;
  final void Function(void Function()) wrapSetState;

  PersonalLibraryMembershipService get libraryMembership =>
      wiring.libraryMembership;
  HomeRegistryHideActions get hideActions => wiring.hideActions;

  bool get canAddToLibrary =>
      AkashaFileService().vaultPath != null &&
      personalLibCtrl.libraries.any((l) => l.isCurated);

  List<BrowseCard> get filteredBrowseCards => wiring.browsePipeline.build(
        allUserItems: getItems(),
        filters: filterCtrl.filterState,
      );

  List<BrowseCard> get personalBrowseCards {
    final library = personalLibCtrl.activeLibrary;
    if (library == null) return const [];
    return wiring.myLibraryPipeline.build(
      getItems(),
      library: library,
      filters: filterCtrl.filterState,
    );
  }

  void onDomainChanged(AppDomain? domain) {
    final needsPrefetch = wiring.filterCoordinator.onDomainChanged(domain);
    rebuild();
    if (needsPrefetch) prefetchRegistry();
  }

  void toggleCategory(MediaCategory category) {
    final needsPrefetch = wiring.filterCoordinator.toggleCategory(category);
    rebuild();
    if (needsPrefetch) prefetchRegistry();
  }

  void clearCategories() {
    final needsPrefetch = wiring.filterCoordinator.clearCategories();
    rebuild();
    if (needsPrefetch) prefetchRegistry();
  }

  void toggleWorkStatus(String label) {
    scheduleRebuild(() => wiring.filterCoordinator.toggleWorkStatus(label));
  }

  void toggleMyStatus(String label) {
    scheduleRebuild(() => wiring.filterCoordinator.toggleMyStatus(label));
  }

  void onEntityScopeChanged(BrowseEntityScope scope) {
    scheduleRebuild(() => wiring.filterCoordinator.setEntityScope(scope));
  }

  Widget buildPosterCard(BrowseCard card) => HomePosterCardFactory(
        allItems: getItems(),
        libraryMembership: libraryMembership,
        hideActions: hideActions,
        isPersonalLibraryMode: navigation.isPersonalLibraryMode,
        canAddToLibrary: canAddToLibrary,
        onOpenItem: workbenchCoord.openBrowseItem,
        onOpenLibraryMenu: (c, pos) => wiring.libraryUi.openWorkLibraryMenu(
          hostContext(),
          card: c,
          anchor: pos,
          canAddToLibrary: canAddToLibrary,
          isCuratedLibraryActive: navigation.isCuratedLibraryActive,
          items: getItems(),
          resolveItemForOpen: workbenchCoord.resolveItemForOpen,
          setState: wrapSetState,
          onCreateLibrary: () => wiring.libraryUi.promptCreateCuratedLibrary(
            hostContext(),
            setState: wrapSetState,
          ),
        ),
        onLibraryDragStarted: navigation.onLibraryDragStarted,
      ).build(card);

  Future<void> onCuratedReorder(
    List<BrowseCard> cards,
    int oldIndex,
    int newIndex,
  ) async {
    await PersonalLibraryView.applyCuratedGridReorder(
      membership: libraryMembership,
      personalLibCtrl: personalLibCtrl,
      visibleCards: cards,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    if (isMounted()) rebuild();
  }
}
