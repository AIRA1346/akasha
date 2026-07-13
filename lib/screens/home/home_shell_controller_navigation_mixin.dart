import '../../../models/browse_entity_scope.dart';
import 'app_destination.dart';
import 'home_shell_controller_base.dart';

/// Sidebar·mode navigation.
mixin HomeShellControllerNavigationMixin on HomeShellControllerBase {
  void toggleSidebar() => navigation.toggleSidebar();

  Future<void> loadDashboards() => navigation.loadDashboards();

  Future<void> loadPersonalLibraries() => navigation.loadPersonalLibraries();

  Future<void> loadCollectibleCollections() =>
      navigation.loadCollectibleCollections();

  Future<void> selectDashboard(String id) => navigation.selectDashboard(id);

  Future<void> goHome() => navigation.goHome();

  Future<void> goExplore() => navigation.goExplore();

  Future<void> goLibrary() => navigation.goLibrary();

  Future<void> goCollection() => navigation.goCollection();

  Future<void> goKnowledgeGraph() => navigation.goKnowledgeGraph();

  Future<void> selectDestination(AppDestination destination) =>
      navigation.selectDestination(destination);

  Future<void> goExploreEntities(BrowseEntityScope scope) =>
      navigation.goExploreEntities(scope);

  void selectPersonalLibrary(String id) => navigation.selectPersonalLibrary(id);

  void selectCollectibleCollection(String id) =>
      navigation.selectCollectibleCollection(id);

  void selectTimeline() => navigation.selectTimeline();

  void onLibraryDragStarted() => navigation.onLibraryDragStarted();
}
