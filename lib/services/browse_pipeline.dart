import '../models/browse_card.dart';
import '../models/enums.dart';
import '../models/registry_work.dart';
import '../core/ports/registry_port.dart';
import '../models/akasha_item.dart';
import 'franchise_fusion_service.dart';
import 'works_registry.dart';

/// 홈 그리드용 필터 입력 (HomeScreen 상태의 스냅샷)
class BrowseFilterState {
  final Set<MediaCategory> categories;
  final Set<String> workStatuses;
  final Set<String> myStatuses;

  const BrowseFilterState({
    this.categories = const {},
    this.workStatuses = const {},
    this.myStatuses = const {},
  });
}

/// userFiltered → registry → fuse → status filter 파이프라인
class BrowsePipeline {
  const BrowsePipeline(this._registryPort);

  final RegistryPort _registryPort;

  List<BrowseCard> build({
    required List<AkashaItem> allUserItems,
    required BrowseFilterState filters,
  }) {
    final userFiltered = _filterUserItems(allUserItems, filters);
    final registryWorks = _resolveRegistryWorks(filters);
    final fused = FranchiseFusionService.fuse(
      userFiltered: userFiltered,
      registryWorks: registryWorks,
      allUserItems: allUserItems,
      selectedCategories: filters.categories,
    );
    return applyStatusFilters(fused, filters);
  }

  List<BrowseCard> applyStatusFilters(
    List<BrowseCard> cards,
    BrowseFilterState filters,
  ) =>
      _applyStatusFilters(cards, filters);

  List<AkashaItem> _filterUserItems(
    List<AkashaItem> items,
    BrowseFilterState filters,
  ) {
    return items.where((item) {
      if (filters.categories.isNotEmpty &&
          !filters.categories.contains(item.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<RegistryWork> _resolveRegistryWorks(BrowseFilterState filters) {
    if (filters.categories.isEmpty) {
      return _registryPort.getFilteredWorksSync(category: null);
    }

    final works = <RegistryWork>[];
    for (final cat in filters.categories) {
      works.addAll(_registryPort.getFilteredWorksSync(category: cat));
    }
    return works;
  }

  List<BrowseCard> _applyStatusFilters(
    List<BrowseCard> cards,
    BrowseFilterState filters,
  ) {
    return cards.where((card) {
      final item = card.item;
      if (filters.workStatuses.isNotEmpty &&
          !filters.workStatuses.contains(item.workStatusLabel)) {
        return false;
      }
      if (filters.myStatuses.isNotEmpty &&
          !filters.myStatuses.contains(item.myStatusLabel)) {
        return false;
      }
      return true;
    }).toList();
  }
}
