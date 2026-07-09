// Discovery Product KPI — 기술 통과 이후 제품·정책 게이트.
//
// AKASHA = "많이 모은 DB" ≠ 목표
// AKASHA = "사용자에게 가치 있는 작품 사전"
library;

class DiscoveryProductKpi {
  final int selectedCount;
  final int productValuePassedCount;
  final int searchGapResolvedCount;
  final int independentValueCount;
  final int userValueHighCount;

  const DiscoveryProductKpi({
    this.selectedCount = 0,
    this.productValuePassedCount = 0,
    this.searchGapResolvedCount = 0,
    this.independentValueCount = 0,
    this.userValueHighCount = 0,
  });

  /// User Value + Product Review 통과 비율
  double get userValueCoverage =>
      selectedCount == 0 ? 0 : productValuePassedCount / selectedCount;

  /// 실제 사용자 검색 Gap 해소 (0건→발견)
  double get userSearchGapResolved =>
      selectedCount == 0 ? 0 : searchGapResolvedCount / selectedCount;

  /// AniList 없이도 AKASHA에 남을 가치
  double get independentRegistryValue =>
      selectedCount == 0 ? 0 : independentValueCount / selectedCount;

  /// 5b patch — Product Value Review 통과 후에만
  bool get recommend5bPatch =>
      selectedCount >= 5 &&
      userValueCoverage >= 0.8 &&
      userSearchGapResolved >= 0.8 &&
      independentRegistryValue >= 0.9;

  Map<String, dynamic> toJson() => {
        'selectedCount': selectedCount,
        'productValuePassedCount': productValuePassedCount,
        'searchGapResolvedCount': searchGapResolvedCount,
        'independentValueCount': independentValueCount,
        'userValueHighCount': userValueHighCount,
        'userValueCoverage': userValueCoverage,
        'userSearchGapResolved': userSearchGapResolved,
        'independentRegistryValue': independentRegistryValue,
        'recommend5bPatch': recommend5bPatch,
      };
}
