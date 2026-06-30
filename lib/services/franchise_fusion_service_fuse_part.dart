part of 'franchise_fusion_service.dart';

List<BrowseCard> _franchiseFusionFuse({
  required List<AkashaItem> userFiltered,
  required List<RegistryWork> registryWorks,
  required List<AkashaItem> allUserItems,
  required Set<MediaCategory> selectedCategories,
}) {
  final allUserWorkIds = allUserItems
      .map((e) => e.workId)
      .where((id) => id.isNotEmpty)
      .toSet();
  final trackedWorkIds = _franchiseFusionArchivedWorkIds(allUserItems);

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
    if (!_franchiseFusionFranchiseInScope(group, registryWorks, userFiltered)) {
      continue;
    }
    if (!_franchiseFusionFranchiseHasVisibleMember(group)) continue;

    emittedFranchises.add(group.id);
    final hasUserMember = allUserItems.any(
      (item) => FranchiseRegistry.groupFor(item.workId)?.id == group.id,
    );

    final representative = hasUserMember
        ? _franchiseFusionPickRepresentativeUserItem(group, allUserItems)
        : _franchiseFusionCreateVirtualFromPrimary(group);

    cards.add(
      BrowseCard(
        item: _franchiseFusionFranchiseCardItem(representative, group),
        formatSlots: _franchiseFusionBuildFormatSlots(
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

    cards.add(
      BrowseCard(
        item: item,
        formatSlots: _franchiseFusionSingleSlotFromItem(
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
        item: _franchiseFusionCreateVirtualFromRegistryWork(work),
        formatSlots: _franchiseFusionSingleSlotFromRegistryWork(
          work,
          trackedWorkIds: trackedWorkIds,
          selectedCategories: selectedCategories,
        ),
      ),
    );
  }

  return cards;
}

List<BrowseCard> _franchiseFusionFuseScoped({
  required List<AkashaItem> memberItems,
  required List<AkashaItem> allUserItems,
  required Set<MediaCategory> selectedCategories,
}) {
  if (memberItems.isEmpty) return const [];

  final trackedWorkIds = _franchiseFusionArchivedWorkIds(allUserItems);
  final memberWorkIds = memberItems
      .map((e) => e.workId)
      .where((id) => id.isNotEmpty)
      .toSet();

  final byFranchise = <String, List<AkashaItem>>{};
  final standalone = <AkashaItem>[];

  for (final item in memberItems) {
    final group = FranchiseRegistry.groupFor(item.workId);
    if (group == null) {
      standalone.add(item);
      continue;
    }
    byFranchise.putIfAbsent(group.id, () => []).add(item);
  }

  final cards = <BrowseCard>[];

  for (final entry in byFranchise.entries) {
    final group = FranchiseRegistry.groupFor(entry.value.first.workId);
    if (group == null) {
      standalone.addAll(entry.value);
      continue;
    }

    final members = entry.value;
    if (members.length >= 2) {
      final representative =
          FranchiseRepresentativePicker.pickForGroup(group, members) ??
              members.first;
      cards.add(
        BrowseCard(
          item: _franchiseFusionFranchiseCardItem(representative, group),
          formatSlots: _franchiseFusionBuildFormatSlotsForMemberIds(
            group,
            memberWorkIds: memberWorkIds,
            trackedWorkIds: trackedWorkIds,
            selectedCategories: selectedCategories,
          ),
          franchiseId: group.id,
        ),
      );
    } else {
      standalone.add(members.first);
    }
  }

  for (final item in standalone) {
    cards.add(
      BrowseCard(
        item: item,
        formatSlots: _franchiseFusionSingleSlotFromItem(
          item,
          trackedWorkIds: trackedWorkIds,
          selectedCategories: selectedCategories,
        ),
      ),
    );
  }

  return cards;
}
