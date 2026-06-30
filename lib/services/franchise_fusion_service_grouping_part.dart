part of 'franchise_fusion_service.dart';

bool _franchiseFusionFranchiseInScope(
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
Set<String> _franchiseFusionArchivedWorkIds(List<AkashaItem> allUserItems) {
  final vault = AppVault.port;
  final ids = <String>{};
  for (final item in allUserItems) {
    if (item.workId.isEmpty) continue;
    final tracked = vault.vaultPath == null
        ? true
        : vault.isArchivedInVault(item);
    if (!tracked) continue;
    ids.add(item.workId);
    final resolved = WorksRegistry.resolveWorkId(item.workId);
    if (resolved.isNotEmpty) ids.add(resolved);
  }
  return ids;
}

bool _franchiseFusionFranchiseHasVisibleMember(FranchiseGroup group) {
  return group.members.any(
    (member) => !UserRegistryPreferences.instance.isHidden(member),
  );
}
