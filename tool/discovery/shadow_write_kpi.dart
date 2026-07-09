// Shadow Write KPI — Registry 영향 측정 (실제 쓰기 없음).
library;

class ShadowWriteKpi {
  final int inputDrafts;
  final int wouldCreate;
  final int wouldMerge;
  final int mergeCandidates;
  final int wouldReject;
  final Map<String, int> targetShardDistribution;
  final Map<String, int> qualityScoreDistribution;
  final Map<String, int> qualityTierDistribution;
  final double duplicateRate;
  final int qualityScoreMin;
  final int qualityScoreMax;
  final double qualityScoreMean;
  final RegistryBuildSimulation registrySimulation;

  const ShadowWriteKpi({
    this.inputDrafts = 0,
    this.wouldCreate = 0,
    this.wouldMerge = 0,
    this.mergeCandidates = 0,
    this.wouldReject = 0,
    this.targetShardDistribution = const {},
    this.qualityScoreDistribution = const {},
    this.qualityTierDistribution = const {},
    this.duplicateRate = 0,
    this.qualityScoreMin = 0,
    this.qualityScoreMax = 0,
    this.qualityScoreMean = 0,
    this.registrySimulation = const RegistryBuildSimulation(),
  });

  /// shard 편중: 최대 버킷 비율 (wouldCreate 기준)
  double get maxShardConcentration {
    if (wouldCreate == 0 || targetShardDistribution.isEmpty) return 0;
    final max = targetShardDistribution.values.reduce((a, b) => a > b ? a : b);
    return max / wouldCreate;
  }

  /// tier 0~1에 몰렸는지 (wouldCreate 기준)
  double get lowTierRatio {
    if (wouldCreate == 0) return 0;
    final low = (qualityTierDistribution['0'] ?? 0) +
        (qualityTierDistribution['1'] ?? 0);
    return low / wouldCreate;
  }

  /// 정책·계약 위반 없음 (dedupe mergeCandidate는 실패 아님)
  bool get shadowPassed => wouldReject == 0;

  /// Discovery가 외부 DB 미러링으로 변질되지 않음
  bool get mirroringIntegrityPassed =>
      wouldReject == 0 && wouldCreate + wouldMerge + mergeCandidates == inputDrafts;

  Map<String, dynamic> toJson() => {
        'inputDrafts': inputDrafts,
        'wouldCreate': wouldCreate,
        'wouldMerge': wouldMerge,
        'mergeCandidates': mergeCandidates,
        'wouldReject': wouldReject,
        'duplicateRate': duplicateRate,
        'mirroringIntegrityPassed': mirroringIntegrityPassed,
        'targetShardDistribution': targetShardDistribution,
        'qualityScoreDistribution': qualityScoreDistribution,
        'qualityTierDistribution': qualityTierDistribution,
        'qualityScoreMin': qualityScoreMin,
        'qualityScoreMax': qualityScoreMax,
        'qualityScoreMean': qualityScoreMean,
        'maxShardConcentration': maxShardConcentration,
        'lowTierRatio': lowTierRatio,
        'registrySimulation': registrySimulation.toJson(),
        'shadowPassed': shadowPassed,
      };
}

class RegistryBuildSimulation {
  final int existingEntryCount;
  final int projectedEntryCount;
  final int durationMs;
  final int searchIndexEntriesBuilt;

  const RegistryBuildSimulation({
    this.existingEntryCount = 0,
    this.projectedEntryCount = 0,
    this.durationMs = 0,
    this.searchIndexEntriesBuilt = 0,
  });

  Map<String, dynamic> toJson() => {
        'existingEntryCount': existingEntryCount,
        'projectedEntryCount': projectedEntryCount,
        'durationMs': durationMs,
        'searchIndexEntriesBuilt': searchIndexEntriesBuilt,
      };
}
