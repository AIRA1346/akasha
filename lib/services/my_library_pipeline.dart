import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import '../models/personal_library_config.dart';
import '../utils/archived_works_query.dart';
import 'franchise_fusion_service.dart';

/// 나만의 서재 전용 파이프라인 — 사전 가상 카드 없이 아카이브 작품만 IP 1카드로 표시
class MyLibraryPipeline {
  static List<BrowseCard> build(
    List<AkashaItem> allUserItems, {
    PersonalLibraryConfig? library,
    Set<MediaCategory>? categories,
  }) {
    final categoryFilter = categories ?? library?.categories ?? const {};
    var archived = ArchivedWorksQuery.archivedItems(allUserItems);
    if (categoryFilter.isNotEmpty) {
      archived = archived
          .where((item) => categoryFilter.contains(item.category))
          .toList();
    }
    if (archived.isEmpty) return const [];

    return FranchiseFusionService.fuse(
      userFiltered: archived,
      registryWorks: const [],
      allUserItems: allUserItems,
      selectedCategories: categoryFilter,
    );
  }
}
