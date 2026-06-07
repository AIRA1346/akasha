import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../utils/archived_works_query.dart';
import 'franchise_fusion_service.dart';

/// 나의 서재 전용 파이프라인 — 사전 가상 카드 없이 아카이브 작품만 IP 1카드로 표시
class MyLibraryPipeline {
  static List<BrowseCard> build(List<AkashaItem> allUserItems) {
    final archived = ArchivedWorksQuery.archivedItems(allUserItems);
    if (archived.isEmpty) return const [];

    return FranchiseFusionService.fuse(
      userFiltered: archived,
      registryWorks: const [],
      allUserItems: allUserItems,
      selectedCategories: const {},
    );
  }
}
