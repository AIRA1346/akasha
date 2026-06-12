import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/personal_library_config.dart';
import 'browse_pipeline.dart';
import 'franchise_fusion_service.dart';
import '../utils/archived_works_query.dart';
import 'franchise_registry.dart';
import 'works_registry.dart';

/// 나만의 서재 전용 파이프라인 — 사전 가상 카드 없이 아카이브 작품만 IP 1카드로 표시
class MyLibraryPipeline {
  static List<BrowseCard> build(
    List<AkashaItem> allUserItems, {
    required PersonalLibraryConfig library,
    BrowseFilterState filters = const BrowseFilterState(),
  }) {
    if (library.isCurated) {
      return _buildCurated(allUserItems, library: library, filters: filters);
    }
    return _buildFilterMode(allUserItems, filters: filters);
  }

  static List<BrowseCard> _buildFilterMode(
    List<AkashaItem> allUserItems, {
    required BrowseFilterState filters,
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

  static List<BrowseCard> _buildCurated(
    List<AkashaItem> allUserItems, {
    required PersonalLibraryConfig library,
    required BrowseFilterState filters,
  }) {
    if (library.memberOrder.isEmpty) return const [];

    final memberIds = library.memberWorkIds;
    var members = ArchivedWorksQuery.archivedItems(allUserItems).where((item) {
      if (item.workId.isEmpty) return false;
      return WorksRegistry.setContainsWorkId(memberIds, item.workId);
    }).toList();

    if (filters.domain != null) {
      members =
          members.where((item) => item.domain == filters.domain).toList();
    }

    if (filters.categories.isNotEmpty) {
      members = members
          .where((item) => filters.categories.contains(item.category))
          .toList();
    }

    if (members.isEmpty) return const [];

    final fused = FranchiseFusionService.fuseScoped(
      memberItems: members,
      allUserItems: allUserItems,
      selectedCategories: filters.categories,
    );

    final filtered = BrowsePipeline.applyStatusFilters(fused, filters);
    return _sortByMemberOrder(filtered, library.memberOrder);
  }

  static List<BrowseCard> _sortByMemberOrder(
    List<BrowseCard> cards,
    List<String> memberOrder,
  ) {
    final orderIndex = <String, int>{};
    for (var i = 0; i < memberOrder.length; i++) {
      orderIndex[memberOrder[i]] = i;
      final resolved = WorksRegistry.resolveWorkId(memberOrder[i]);
      if (resolved.isNotEmpty) {
        orderIndex.putIfAbsent(resolved, () => i);
      }
    }

    int indexFor(BrowseCard card) {
      final indices = <int>[];

      void addForWorkId(String workId) {
        if (workId.isEmpty) return;
        final direct = orderIndex[workId];
        if (direct != null) indices.add(direct);
        final resolved = WorksRegistry.resolveWorkId(workId);
        if (resolved.isNotEmpty) {
          final resolvedIndex = orderIndex[resolved];
          if (resolvedIndex != null) indices.add(resolvedIndex);
        }
      }

      addForWorkId(card.item.workId);

      final franchiseId = card.franchiseId;
      if (franchiseId != null) {
        final group = FranchiseRegistry.groupById(franchiseId);
        if (group != null) {
          for (final member in group.members) {
            addForWorkId(member);
          }
        }
      }

      if (indices.isEmpty) return 1 << 30;
      return indices.reduce((a, b) => a < b ? a : b);
    }

    final sorted = List<BrowseCard>.from(cards)
      ..sort((a, b) {
        final cmp = indexFor(a).compareTo(indexFor(b));
        if (cmp != 0) return cmp;
        return a.item.title.compareTo(b.item.title);
      });
    return sorted;
  }
}
