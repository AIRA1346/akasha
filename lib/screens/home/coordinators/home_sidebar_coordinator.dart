import '../../../models/personal_library_config.dart';
import '../../../models/entity_gallery_sort.dart';
import '../../../utils/helpers.dart';
import '../home_collectible_collection_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_personal_library_controller.dart';
import '../home_section_preferences.dart';
import 'home_filter_coordinator.dart';

/// 사이드바 대시보드·나만의 서재 선택 및 정렬 정책.
class HomeSidebarCoordinator {
  HomeSidebarCoordinator({
    required this.personalLibCtrl,
    required this.collectionCtrl,
    required this.dashboardCtrl,
    required this.sectionPrefs,
    required this.filterCoordinator,
  });

  final HomePersonalLibraryController personalLibCtrl;
  final HomeCollectibleCollectionController collectionCtrl;
  final HomeDashboardController dashboardCtrl;
  final HomeSectionPreferences sectionPrefs;
  final HomeFilterCoordinator filterCoordinator;

  bool get isPersonalLibraryMode => filterCoordinator.isPersonalLibraryMode;

  bool get isCollectibleCollectionMode =>
      filterCoordinator.isCollectibleCollectionMode;

  bool get isCuratedLibraryActive {
    final lib = personalLibCtrl.activeLibrary;
    return isPersonalLibraryMode && lib != null && lib.isCurated;
  }

  Future<bool> loadDashboards() async {
    await dashboardCtrl.load();
    filterCoordinator.applyDashboardFilters(
      dashboardCtrl.activeFilterSnapshot,
    );
    return personalLibCtrl.sidebarMode == SidebarSelectionMode.dashboard;
  }

  Future<void> loadPersonalLibraries() async {
    await personalLibCtrl.load();
    if (personalLibCtrl.sidebarMode == SidebarSelectionMode.personalLibrary) {
      filterCoordinator.applyPersonalLibraryFilterSnapshot(
        personalLibCtrl.activeLibrary,
      );
      sanitizeLibrarySortForActiveLibrary();
    }
  }

  Future<void> loadCollectibleCollections() async {
    await collectionCtrl.load();
  }

  void selectCollectibleCollection(String id) {
    collectionCtrl.selectCollection(id, personalLibCtrl: personalLibCtrl);
    final col = collectionCtrl.activeCollection;
    if (col?.isCurated == true &&
        !sectionPrefs.entityGallerySort.isManualOrder) {
      sectionPrefs.entityGallerySort = EntityGallerySortCriteria.manualOrder;
      sectionPrefs.saveEntityGallerySort(EntityGallerySortCriteria.manualOrder);
    }
  }

  void selectDashboard(String id) {
    dashboardCtrl.select(id);
    personalLibCtrl.selectDashboardMode();
    filterCoordinator.applyDashboardFilters(
      dashboardCtrl.activeFilterSnapshot,
    );
    sanitizeLibrarySortForActiveLibrary();
  }

  void selectPersonalLibrary(String id) {
    final wasCurated = isCuratedLibraryActive;
    PersonalLibraryConfig? target;
    for (final lib in personalLibCtrl.libraries) {
      if (lib.id == id) {
        target = lib;
        break;
      }
    }
    final willBeCurated = target?.isCurated ?? false;

    personalLibCtrl.selectPersonal(id);
    filterCoordinator.applyPersonalLibraryFilterSnapshot(
      personalLibCtrl.activeLibrary,
    );
    syncLibrarySortOnPersonalLibraryChange(
      wasCurated: wasCurated,
      nowCurated: willBeCurated,
    );
  }

  void selectTimeline() {
    personalLibCtrl.selectTimelineMode();
  }

  void sanitizeLibrarySortForActiveLibrary() {
    if (isCuratedLibraryActive) return;
    if (sectionPrefs.librarySort.isManualOrder) {
      sectionPrefs.librarySort = SortCriteria.titleAsc;
      sectionPrefs.saveSort('library', SortCriteria.titleAsc);
    }
  }

  void syncLibrarySortOnPersonalLibraryChange({
    required bool wasCurated,
    required bool nowCurated,
  }) {
    if (nowCurated) {
      if (!wasCurated) {
        sectionPrefs.librarySort = SortCriteria.manualOrder;
        sectionPrefs.saveSort('library', SortCriteria.manualOrder);
      }
      return;
    }
    sanitizeLibrarySortForActiveLibrary();
  }
}
