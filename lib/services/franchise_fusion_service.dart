import '../core/app_vault.dart';
import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import '../models/format_slot.dart';
import '../models/franchise_group.dart';
import '../utils/helpers.dart';
import 'franchise_registry.dart';
import 'franchise_representative_picker.dart';
import 'registry_visibility_service.dart';
import 'user_registry_preferences.dart';
import 'works_registry.dart';

part 'franchise_fusion_service_fuse_part.dart';
part 'franchise_fusion_service_slots_part.dart';
part 'franchise_fusion_service_grouping_part.dart';
part 'franchise_fusion_service_representative_part.dart';

/// browse 그리드용 franchise 통합 fusion
class FranchiseFusionService {
  /// 프랜차이즈 전체 매체 슬롯 (상세·검색 UI용)
  static List<FormatSlot> formatSlotsForGroup(
    FranchiseGroup group, {
    required List<AkashaItem> allUserItems,
    Set<MediaCategory> selectedCategories = const {},
  }) {
    return _franchiseFusionBuildFormatSlots(
      group,
      trackedWorkIds: _franchiseFusionArchivedWorkIds(allUserItems),
      selectedCategories: selectedCategories,
    );
  }

  static List<FormatSlot> formatSlotsForWorkId(
    String workId, {
    required List<AkashaItem> allUserItems,
    Set<MediaCategory> selectedCategories = const {},
  }) {
    final group = FranchiseRegistry.groupFor(workId);
    if (group == null) return const [];
    return formatSlotsForGroup(
      group,
      allUserItems: allUserItems,
      selectedCategories: selectedCategories,
    );
  }

  /// 검색 서브타이틀: 「만화 · 라노벨 · 애니」
  static String franchiseFormatLabels(FranchiseGroup group) =>
      _franchiseFusionFranchiseFormatLabels(group);

  static List<BrowseCard> fuse({
    required List<AkashaItem> userFiltered,
    required List<RegistryWork> registryWorks,
    required List<AkashaItem> allUserItems,
    required Set<MediaCategory> selectedCategories,
  }) =>
      _franchiseFusionFuse(
        userFiltered: userFiltered,
        registryWorks: registryWorks,
        allUserItems: allUserItems,
        selectedCategories: selectedCategories,
      );

  /// 큐레이션 서재 — 멤버십 집합 안에서만 franchise 그룹핑
  static List<BrowseCard> fuseScoped({
    required List<AkashaItem> memberItems,
    required List<AkashaItem> allUserItems,
    required Set<MediaCategory> selectedCategories,
  }) =>
      _franchiseFusionFuseScoped(
        memberItems: memberItems,
        allUserItems: allUserItems,
        selectedCategories: selectedCategories,
      );
}
