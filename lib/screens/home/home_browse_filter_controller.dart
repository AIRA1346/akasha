import '../../models/browse_entity_scope.dart';
import '../../models/enums.dart';
import '../../services/browse_pipeline.dart';
import '../../utils/helpers.dart';
import 'home_dashboard_controller.dart';

/// 홈 browse 필터 상태 + 대시보드 동기화
class HomeBrowseFilterController {
  final Set<MediaCategory> categories = {};
  final Set<String> workStatuses = {};
  final Set<String> myStatuses = {};
  BrowseEntityScope entityScope = BrowseEntityScope.work;
  String? highlightEntityId;

  bool get hasAnyFilters =>
      categories.isNotEmpty ||
      workStatuses.isNotEmpty ||
      myStatuses.isNotEmpty ||
      highlightEntityId != null;

  BrowseFilterState get filterState => BrowseFilterState(
        categories: Set.from(categories),
        workStatuses: Set.from(workStatuses),
        myStatuses: Set.from(myStatuses),
      );

  void applySnapshot(DashboardFilterSnapshot snap) {
    categories
      ..clear()
      ..addAll(snap.categories);
    workStatuses
      ..clear()
      ..addAll(snap.workStatuses);
    myStatuses
      ..clear()
      ..addAll(snap.myStatuses);
  }

  void syncToDashboard(HomeDashboardController dashboardCtrl) {
    dashboardCtrl.syncActiveFromFilters(
      categories: categories,
      workStatuses: workStatuses,
      myStatuses: myStatuses,
    );
    dashboardCtrl.save();
  }

  void toggleCategory(MediaCategory category) {
    if (!categories.remove(category)) {
      categories.add(category);
    }
    pruneInvalidStatuses();
  }

  void clearCategories() {
    categories.clear();
    workStatuses.clear();
    myStatuses.clear();
  }

  void toggleWorkStatus(String label) {
    if (!workStatuses.remove(label)) {
      workStatuses.add(label);
    }
  }

  void toggleMyStatus(String label) {
    if (!myStatuses.remove(label)) {
      myStatuses.add(label);
    }
  }

  void setEntityScope(BrowseEntityScope scope) {
    entityScope = scope;
    highlightEntityId = null;
  }

  void highlightCatalogEntity(String entityId) {
    highlightEntityId = entityId;
  }

  void clearEntityHighlight() {
    highlightEntityId = null;
  }

  void pruneInvalidStatuses() {
    if (categories.isEmpty) {
      workStatuses.clear();
      myStatuses.clear();
      return;
    }
    final validWorkOpts = <String>{};
    final validMyOpts = <String>{};
    for (final cat in categories) {
      validWorkOpts.addAll(workStatusOptionsFor(cat));
      validMyOpts.addAll(myStatusOptionsFor(cat));
    }
    workStatuses.retainAll(validWorkOpts);
    myStatuses.retainAll(validMyOpts);
  }
}
