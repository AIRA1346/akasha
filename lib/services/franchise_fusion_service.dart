import '../models/akasha_item.dart';
import '../models/browse_card.dart';
import '../models/enums.dart';
import '../models/format_slot.dart';
import '../models/franchise_group.dart';
import '../utils/helpers.dart';
import 'file_service.dart';
import 'franchise_registry.dart';
import 'franchise_representative_picker.dart';
import 'registry_visibility_service.dart';
import 'user_registry_preferences.dart';
import 'works_registry.dart';

/// browse 그리드용 franchise 통합 fusion
class FranchiseFusionService {
  /// 프랜차이즈 전체 매체 슬롯 (상세·검색 UI용)
  static List<FormatSlot> formatSlotsForGroup(
    FranchiseGroup group, {
    required List<AkashaItem> allUserItems,
    Set<MediaCategory> selectedCategories = const {},
  }) {
    return _buildFormatSlots(
      group,
      trackedWorkIds: _archivedWorkIds(allUserItems),
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
  static String franchiseFormatLabels(FranchiseGroup group) {
    final labels = <String>[];
    for (final memberId in group.members) {
      final work = WorksRegistry.getWorkById(memberId);
      if (work != null) labels.add(shortCategoryLabel(work.category));
    }
    return labels.join(' · ');
  }

  static List<BrowseCard> fuse({
    required List<AkashaItem> userFiltered,
    required List<RegistryWork> registryWorks,
    required List<AkashaItem> allUserItems,
    required Set<MediaCategory> selectedCategories,
  }) {
    final allUserWorkIds = allUserItems
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final trackedWorkIds = _archivedWorkIds(allUserItems);

    final franchisesInScope = <String, FranchiseGroup>{};
    for (final item in allUserItems) {
      final group = FranchiseRegistry.groupFor(item.workId);
      if (group != null) franchisesInScope[group.id] = group;
    }
    for (final work in registryWorks) {
      final group = FranchiseRegistry.groupFor(work.workId);
      if (group != null) franchisesInScope[group.id] = group;
    }

    final emittedFranchises = <String>{};
    final cards = <BrowseCard>[];

    for (final group in franchisesInScope.values) {
      if (!_franchiseInScope(group, registryWorks, userFiltered)) continue;
      if (!_franchiseHasVisibleMember(group)) continue;

      emittedFranchises.add(group.id);
      final hasUserMember = allUserItems.any(
        (item) => FranchiseRegistry.groupFor(item.workId)?.id == group.id,
      );

      final representative = hasUserMember
          ? (_pickRepresentativeUserItem(group, allUserItems))
          : _createVirtualFromPrimary(group);

      cards.add(
        BrowseCard(
          item: _franchiseCardItem(representative, group),
          formatSlots: _buildFormatSlots(
            group,
            trackedWorkIds: trackedWorkIds,
            selectedCategories: selectedCategories,
          ),
          franchiseId: group.id,
        ),
      );
    }

    for (final item in userFiltered) {
      final group = FranchiseRegistry.groupFor(item.workId);
      if (group != null && emittedFranchises.contains(group.id)) continue;

      final key = item.workId.isNotEmpty
          ? item.workId
          : '${item.category.name}::${item.title}';

      cards.add(
        BrowseCard(
          item: item,
          formatSlots: _singleSlotFromItem(
            item,
            trackedWorkIds: trackedWorkIds,
            selectedCategories: selectedCategories,
          ),
        ),
      );
    }

    for (final work in registryWorks) {
      final group = FranchiseRegistry.groupFor(work.workId);
      if (group != null && emittedFranchises.contains(group.id)) continue;

      if (!RegistryVisibilityService.shouldMaterializeVirtual(
        workId: work.workId,
        userWorkIds: allUserWorkIds,
      )) {
        continue;
      }

      cards.add(
        BrowseCard(
          item: _createVirtualFromRegistryWork(work),
          formatSlots: _singleSlotFromRegistryWork(
            work,
            trackedWorkIds: trackedWorkIds,
            selectedCategories: selectedCategories,
          ),
        ),
      );
    }

    return cards;
  }

  static bool _franchiseInScope(
    FranchiseGroup group,
    List<RegistryWork> registryWorks,
    List<AkashaItem> userFiltered,
  ) {
    final registryHit = group.members.any(
      (member) => registryWorks.any(
        (work) =>
            work.workId == member ||
            WorksRegistry.resolveWorkId(work.workId) ==
                WorksRegistry.resolveWorkId(member),
      ),
    );
    if (registryHit) return true;

    return userFiltered.any(
      (item) => FranchiseRegistry.groupFor(item.workId)?.id == group.id,
    );
  }

  /// 볼트 연동 시 .md 아카이브된 workId만 tracked (배지와 동일 기준)
  static Set<String> _archivedWorkIds(List<AkashaItem> allUserItems) {
    final service = AkashaFileService();
    final ids = <String>{};
    for (final item in allUserItems) {
      if (item.workId.isEmpty) continue;
      final tracked = service.vaultPath == null
          ? true
          : service.isArchivedInVault(item);
      if (!tracked) continue;
      ids.add(item.workId);
      final resolved = WorksRegistry.resolveWorkId(item.workId);
      if (resolved.isNotEmpty) ids.add(resolved);
    }
    return ids;
  }

  static AkashaItem _pickRepresentativeUserItem(
    FranchiseGroup group,
    List<AkashaItem> allUserItems,
  ) {
    return FranchiseRepresentativePicker.pickForGroup(group, allUserItems) ??
        _createVirtualFromPrimary(group);
  }

  static List<FormatSlot> _buildFormatSlots(
    FranchiseGroup group, {
    required Set<String> trackedWorkIds,
    required Set<MediaCategory> selectedCategories,
  }) {
    final slots = <FormatSlot>[];
    for (final memberId in group.members) {
      final slot = _slotForWorkId(
        memberId,
        trackedWorkIds: trackedWorkIds,
        selectedCategories: selectedCategories,
      );
      if (slot != null) slots.add(slot);
    }
    slots.sort(
      (a, b) => categorySortOrder(a.category).compareTo(
        categorySortOrder(b.category),
      ),
    );
    return _disambiguateSlotLabels(slots);
  }

  static List<FormatSlot> _disambiguateSlotLabels(List<FormatSlot> slots) {
    final labelCounts = <String, int>{};
    for (final slot in slots) {
      labelCounts[slot.shortLabel] = (labelCounts[slot.shortLabel] ?? 0) + 1;
    }
    return slots.map((slot) {
      if ((labelCounts[slot.shortLabel] ?? 0) <= 1) return slot;
      final suffix =
          slot.releaseYear != null ? ' ${slot.releaseYear}' : ' ·${slot.workId.split('_').reversed.take(2).join()}';
      return slot.copyWith(shortLabel: '${slot.shortLabel}$suffix');
    }).toList();
  }

  static FormatSlot? _slotForWorkId(
    String workId, {
    required Set<String> trackedWorkIds,
    required Set<MediaCategory> selectedCategories,
  }) {
    final work = WorksRegistry.getWorkById(workId);
    if (work == null) return null;

    final resolved = WorksRegistry.resolveWorkId(workId);
    final prefs = UserRegistryPreferences.instance;

    FormatSlotState state;
    if (prefs.isHidden(workId)) {
      state = FormatSlotState.hidden;
    } else if (WorksRegistry.setContainsWorkId(trackedWorkIds, workId)) {
      state = FormatSlotState.tracked;
    } else {
      state = FormatSlotState.catalogOnly;
    }

    final dimmed = selectedCategories.isNotEmpty &&
        !selectedCategories.contains(work.category);

    return FormatSlot(
      workId: work.workId,
      category: work.category,
      shortLabel: shortCategoryLabel(work.category),
      releaseYear: work.releaseYear,
      state: state,
      dimmedByFilter: dimmed,
    );
  }

  static List<FormatSlot> _singleSlotFromItem(
    AkashaItem item, {
    required Set<String> trackedWorkIds,
    required Set<MediaCategory> selectedCategories,
  }) {
    if (item.workId.isEmpty) return const [];
    final slot = _slotForWorkId(
      item.workId,
      trackedWorkIds: trackedWorkIds,
      selectedCategories: selectedCategories,
    );
    return slot == null ? const [] : [slot];
  }

  static List<FormatSlot> _singleSlotFromRegistryWork(
    RegistryWork work, {
    required Set<String> trackedWorkIds,
    required Set<MediaCategory> selectedCategories,
  }) {
    final slot = _slotForWorkId(
      work.workId,
      trackedWorkIds: trackedWorkIds,
      selectedCategories: selectedCategories,
    );
    return slot == null ? const [] : [slot];
  }

  /// 그리드 표시용 — 원본 .md 제목과 무관하게 IP 표시명으로 통일
  static AkashaItem _franchiseCardItem(AkashaItem rep, FranchiseGroup group) {
    final ipTitle = group.localizedDisplayName();
    if (rep.title == ipTitle) return rep;
    final card = createItem(
      workId: rep.workId,
      title: ipTitle,
      category: rep.category,
      domain: rep.domain,
      workStatus: rep.workStatusLabel,
      myStatus: rep.myStatusLabel,
      creator: rep.creator,
      releaseYear: rep.releaseYear,
      rating: rep.rating,
      posterPath: rep.posterPath,
      description: rep.description,
      memorableQuotes: rep.memorableQuotes,
      review: rep.review,
      isHallOfFame: rep.isHallOfFame,
      tags: rep.tags,
    );
    card.filePath = rep.filePath;
    return card;
  }

  static bool _franchiseHasVisibleMember(FranchiseGroup group) {
    return group.members.any(
      (member) => !UserRegistryPreferences.instance.isHidden(member),
    );
  }

  static AkashaItem _createVirtualFromPrimary(FranchiseGroup group) {
    final work = WorksRegistry.getWorkById(group.primaryWorkId);
    if (work == null) {
      return createItem(
        workId: group.primaryWorkId,
        title: group.localizedDisplayName(),
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        myStatus: ContentMyStatus.notStarted.label,
        workStatus: ContentWorkStatus.completed.label,
      );
    }
    return _createVirtualFromRegistryWork(
      work,
      titleOverride: group.localizedDisplayName(),
    );
  }

  static AkashaItem _createVirtualFromRegistryWork(
    RegistryWork work, {
    String? titleOverride,
  }) {
    final defaultMyStatus = work.category.isContentType
        ? ContentMyStatus.notStarted.label
        : GameMyStatus.backlog.label;
    final defaultWorkStatus = work.category.isContentType
        ? ContentWorkStatus.completed.label
        : GameWorkStatus.released.label;

    return createItem(
      workId: work.workId,
      title: titleOverride ?? work.displayTitle(),
      category: work.category,
      domain: work.domain,
      myStatus: defaultMyStatus,
      workStatus: defaultWorkStatus,
      creator: work.creator,
      releaseYear: work.releaseYear,
      rating: 0.0,
      description: work.description,
      tags: work.tags,
    );
  }
}
