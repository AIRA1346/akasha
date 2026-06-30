part of 'franchise_fusion_service.dart';

AkashaItem _franchiseFusionPickRepresentativeUserItem(
  FranchiseGroup group,
  List<AkashaItem> allUserItems,
) {
  return FranchiseRepresentativePicker.pickForGroup(group, allUserItems) ??
      _franchiseFusionCreateVirtualFromPrimary(group);
}

/// 그리드 표시용 — 원본 .md 제목과 무관하게 IP 표시명으로 통일
AkashaItem _franchiseFusionFranchiseCardItem(
  AkashaItem rep,
  FranchiseGroup group,
) {
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

AkashaItem _franchiseFusionCreateVirtualFromPrimary(FranchiseGroup group) {
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
  return _franchiseFusionCreateVirtualFromRegistryWork(
    work,
    titleOverride: group.localizedDisplayName(),
  );
}

AkashaItem _franchiseFusionCreateVirtualFromRegistryWork(
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
