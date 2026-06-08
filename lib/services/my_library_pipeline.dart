import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import 'browse_pipeline.dart';
import 'franchise_fusion_service.dart';
import '../utils/archived_works_query.dart';

/// 나만의 서재 전용 파이프라인 — 사전 가상 카드 없이 아카이브 작품만 IP 1카드로 표시
class MyLibraryPipeline {
  static List<BrowseCard> build(
    List<AkashaItem> allUserItems, {
    BrowseFilterState filters = const BrowseFilterState(),
  }) {
    var archived = ArchivedWorksQuery.archivedItems(allUserItems);

    if (filters.domain != null) {
      archived = archived
          .where((item) => item.domain == filters.domain)
          .toList();
    }

    if (filters.categories.isNotEmpty) {
      archived = archived
          .where((item) => filters.categories.contains(item.category))
          .toList();
    }

    if (archived.isEmpty) return const [];

    final fused = FranchiseFusionService.fuse(
      userFiltered: archived,
      registryWorks: const [],
      allUserItems: allUserItems,
      selectedCategories: filters.categories,
    );

    return BrowsePipeline.applyStatusFilters(fused, filters);
  }
}
