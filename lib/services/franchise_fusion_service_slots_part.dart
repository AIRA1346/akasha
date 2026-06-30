part of 'franchise_fusion_service.dart';

String _franchiseFusionFranchiseFormatLabels(FranchiseGroup group) {
  final labels = <String>[];
  for (final memberId in group.members) {
    final work = WorksRegistry.getWorkById(memberId);
    if (work != null) labels.add(shortCategoryLabel(work.category));
  }
  return labels.join(' · ');
}

List<FormatSlot> _franchiseFusionBuildFormatSlotsForMemberIds(
  FranchiseGroup group, {
  required Set<String> memberWorkIds,
  required Set<String> trackedWorkIds,
  required Set<MediaCategory> selectedCategories,
}) {
  final slots = <FormatSlot>[];
  for (final memberId in group.members) {
    if (!WorksRegistry.setContainsWorkId(memberWorkIds, memberId)) continue;
    final slot = _franchiseFusionSlotForWorkId(
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
  return _franchiseFusionDisambiguateSlotLabels(slots);
}

List<FormatSlot> _franchiseFusionBuildFormatSlots(
  FranchiseGroup group, {
  required Set<String> trackedWorkIds,
  required Set<MediaCategory> selectedCategories,
}) {
  final slots = <FormatSlot>[];
  for (final memberId in group.members) {
    final slot = _franchiseFusionSlotForWorkId(
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
  return _franchiseFusionDisambiguateSlotLabels(slots);
}

List<FormatSlot> _franchiseFusionDisambiguateSlotLabels(List<FormatSlot> slots) {
  final labelCounts = <String, int>{};
  for (final slot in slots) {
    labelCounts[slot.shortLabel] = (labelCounts[slot.shortLabel] ?? 0) + 1;
  }
  return slots.map((slot) {
    if ((labelCounts[slot.shortLabel] ?? 0) <= 1) return slot;
    final suffix = slot.releaseYear != null
        ? ' ${slot.releaseYear}'
        : ' ·${slot.workId.split('_').reversed.take(2).join()}';
    return slot.copyWith(shortLabel: '${slot.shortLabel}$suffix');
  }).toList();
}

FormatSlot? _franchiseFusionSlotForWorkId(
  String workId, {
  required Set<String> trackedWorkIds,
  required Set<MediaCategory> selectedCategories,
}) {
  final work = WorksRegistry.getWorkById(workId);
  if (work == null) return null;

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

List<FormatSlot> _franchiseFusionSingleSlotFromItem(
  AkashaItem item, {
  required Set<String> trackedWorkIds,
  required Set<MediaCategory> selectedCategories,
}) {
  if (item.workId.isEmpty) return const [];
  final slot = _franchiseFusionSlotForWorkId(
    item.workId,
    trackedWorkIds: trackedWorkIds,
    selectedCategories: selectedCategories,
  );
  return slot == null ? const [] : [slot];
}

List<FormatSlot> _franchiseFusionSingleSlotFromRegistryWork(
  RegistryWork work, {
  required Set<String> trackedWorkIds,
  required Set<MediaCategory> selectedCategories,
}) {
  final slot = _franchiseFusionSlotForWorkId(
    work.workId,
    trackedWorkIds: trackedWorkIds,
    selectedCategories: selectedCategories,
  );
  return slot == null ? const [] : [slot];
}
