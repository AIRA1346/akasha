// Discovery KPI 계층 — Technical · Product · Independence · Patch Gate.
library;

/// Contract → Diff (기술)
class DiscoveryTechnicalKpi {
  final int wouldCreate;
  final int mergeCandidates;
  final double coverageDelta;
  final int zeroToHit;

  const DiscoveryTechnicalKpi({
    this.wouldCreate = 0,
    this.mergeCandidates = 0,
    this.coverageDelta = 0,
    this.zeroToHit = 0,
  });

  Map<String, dynamic> toJson() => {
        'wouldCreate': wouldCreate,
        'mergeCandidates': mergeCandidates,
        'coverageDelta': coverageDelta,
        'zeroToHit': zeroToHit,
      };
}

/// Product Value Review (제품)
class DiscoveryProductKpiV2 {
  final int selectedCount;
  final int searchGapResolvedCount;
  final double aliasCoverageIncrease;
  final double searchRecallIncrease;
  final double franchiseCoverageIncrease;

  const DiscoveryProductKpiV2({
    this.selectedCount = 0,
    this.searchGapResolvedCount = 0,
    this.aliasCoverageIncrease = 0,
    this.searchRecallIncrease = 0,
    this.franchiseCoverageIncrease = 0,
  });

  double get userSearchGapResolved => selectedCount == 0
      ? 0
      : searchGapResolvedCount / selectedCount;

  bool get productReviewApproved =>
      selectedCount >= 5 &&
      userSearchGapResolved >= 0.8 &&
      searchRecallIncrease > 0;

  Map<String, dynamic> toJson() => {
        'selectedCount': selectedCount,
        'userSearchGapResolved': userSearchGapResolved,
        'searchGapResolvedCount': searchGapResolvedCount,
        'aliasCoverageIncrease': aliasCoverageIncrease,
        'searchRecallIncrease': searchRecallIncrease,
        'franchiseCoverageIncrease': franchiseCoverageIncrease,
        'productReviewApproved': productReviewApproved,
      };
}

/// AniList Removal Test (독립성)
class DiscoveryIndependenceKpi {
  final int selectedCount;
  final int passCount;
  final int failCount;

  const DiscoveryIndependenceKpi({
    this.selectedCount = 0,
    this.passCount = 0,
    this.failCount = 0,
  });

  double get independentRegistryValue =>
      selectedCount == 0 ? 0 : passCount / selectedCount;

  double get percentWorksJustifiedWithoutAniList => independentRegistryValue;

  bool get anilistRemovalTestPassed =>
      selectedCount >= 5 && independentRegistryValue >= 0.9;

  Map<String, dynamic> toJson() => {
        'selectedCount': selectedCount,
        'passCount': passCount,
        'failCount': failCount,
        'independentRegistryValue': independentRegistryValue,
        'percentWorksJustifiedWithoutAniList':
            percentWorksJustifiedWithoutAniList,
        'anilistRemovalTestPassed': anilistRemovalTestPassed,
      };
}

/// 5b — 세 게이트 모두 true일 때만 검토
class DiscoveryPatchGate {
  final bool recommend5bPatch;
  final bool productReviewApproved;
  final bool anilistRemovalTestPassed;

  const DiscoveryPatchGate({
    required this.recommend5bPatch,
    required this.productReviewApproved,
    required this.anilistRemovalTestPassed,
  });

  bool get allow5bReview =>
      recommend5bPatch &&
      productReviewApproved &&
      anilistRemovalTestPassed;

  Map<String, dynamic> toJson() => {
        'recommend5bPatch': recommend5bPatch,
        'productReviewApproved': productReviewApproved,
        'anilistRemovalTestPassed': anilistRemovalTestPassed,
        'allow5bReview': allow5bReview,
      };
}

DiscoveryProductKpiV2 buildProductKpiV2({
  required int selectedCount,
  required int searchGapResolvedCount,
  required double aliasCoverageBefore,
  required double aliasCoverageAfter,
  required int zeroToHit,
  required int searchProbeCount,
  required int franchiseGainCount,
}) {
  final recallIncrease = searchProbeCount == 0
      ? 0.0
      : zeroToHit / searchProbeCount;

  return DiscoveryProductKpiV2(
    selectedCount: selectedCount,
    searchGapResolvedCount: searchGapResolvedCount,
    aliasCoverageIncrease: aliasCoverageAfter - aliasCoverageBefore,
    searchRecallIncrease: recallIncrease,
    franchiseCoverageIncrease: selectedCount == 0
        ? 0
        : franchiseGainCount / selectedCount,
  );
}

DiscoveryTechnicalKpi buildTechnicalKpi({
  required int wouldCreate,
  required int mergeCandidates,
  required double coverageDelta,
  required int zeroToHit,
}) {
  return DiscoveryTechnicalKpi(
    wouldCreate: wouldCreate,
    mergeCandidates: mergeCandidates,
    coverageDelta: coverageDelta,
    zeroToHit: zeroToHit,
  );
}

DiscoveryPatchGate buildPatchGate({
  required DiscoveryTechnicalKpi technical,
  required DiscoveryProductKpiV2 product,
  required DiscoveryIndependenceKpi independence,
}) {
  final recommend5b = technical.wouldCreate >= 5 &&
      technical.zeroToHit >= 5 &&
      technical.coverageDelta >= 0.5;

  return DiscoveryPatchGate(
    recommend5bPatch: recommend5b,
    productReviewApproved: product.productReviewApproved,
    anilistRemovalTestPassed: independence.anilistRemovalTestPassed,
  );
}
