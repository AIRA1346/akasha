/// 작품 품질 신호(원본) → qualityScore / qualityTier (빌드 시 파생)
///
/// v1 Tier 1: Fact only — poster·description 점수 없음.
/// - shard에는 [qualitySignals]만 저장 (tier·score 저장 금지)
/// - registry_builder가 search_index에 score·tier 복사
library;

/// 점수 가중치 (총 100) — [akasha-db/SCHEMA.md]
const qualityWeightTitle = 25;
const qualityWeightYear = 15;
const qualityWeightCreator = 15;
const qualityWeightExternalId = 25;
const qualityWeightVerificationEach = 10;

/// 검증 신호 2종 × 10점 = 20
const qualityVerifiedSignalKeys = [
  'externalIdVerified',
  'franchiseVerified',
];

class QualitySignals {
  final bool externalIdVerified;
  final bool franchiseVerified;

  const QualitySignals({
    this.externalIdVerified = false,
    this.franchiseVerified = false,
  });

  Map<String, bool> toJson() => {
        'externalIdVerified': externalIdVerified,
        'franchiseVerified': franchiseVerified,
      };

  static QualitySignals fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QualitySignals();
    bool flag(String key) => json[key] == true;
    return QualitySignals(
      externalIdVerified: flag('externalIdVerified'),
      franchiseVerified: flag('franchiseVerified'),
    );
  }
}

/// 샤드 WorkEntry + franchise 멤버십으로 신호 해석 (저장값 우선, 없으면 유도)
QualitySignals resolveQualitySignals(
  Map<String, dynamic> work, {
  required bool franchiseMember,
}) {
  final stored = work['qualitySignals'];
  final storedMap = stored is Map
      ? Map<String, dynamic>.from(stored)
      : <String, dynamic>{};

  final hasExternalId = _hasExternalId(work);

  final externalIdVerified =
      storedMap['externalIdVerified'] == true && hasExternalId;

  final franchiseVerified =
      storedMap['franchiseVerified'] == true || franchiseMember;

  return QualitySignals(
    externalIdVerified: externalIdVerified,
    franchiseVerified: franchiseVerified,
  );
}

bool _hasExternalId(Map<String, dynamic> work) {
  final externalIds = work['externalIds'];
  if (externalIds is Map) {
    for (final value in externalIds.values) {
      if (value?.toString().trim().isNotEmpty == true) return true;
    }
  }
  final extensions = work['extensions'];
  if (extensions is Map) {
    for (final key in [
      'anilist',
      'anilistId',
      'tmdb',
      'tmdbId',
      'steam',
      'steamAppId',
      'mal',
      'malId',
      'isbn',
      'igdb',
      'igdbId',
    ]) {
      if (extensions[key]?.toString().trim().isNotEmpty == true) {
        return true;
      }
    }
  }
  return false;
}

/// 0–100 품질 점수 (파생값)
int computeQualityScore(
  Map<String, dynamic> work,
  QualitySignals signals,
) {
  var score = 0;

  final title = work['title']?.toString() ?? '';
  final titles = work['titles'];
  if (title.isNotEmpty || (titles is Map && titles.isNotEmpty)) {
    score += qualityWeightTitle;
  }

  final year = int.tryParse(work['releaseYear']?.toString() ?? '');
  if (year != null && year > 0) score += qualityWeightYear;

  final creator = work['creator']?.toString() ?? '';
  if (creator.trim().isNotEmpty) score += qualityWeightCreator;

  if (_hasExternalId(work)) score += qualityWeightExternalId;

  if (signals.externalIdVerified) {
    score += qualityWeightVerificationEach;
  }
  if (signals.franchiseVerified) {
    score += qualityWeightVerificationEach;
  }

  return score.clamp(0, 100);
}

/// 0–5 품질 tier (파생값, UI·랭킹용)
int qualityTierFromScore(int score) {
  if (score >= 95) return 5;
  if (score >= 80) return 4;
  if (score >= 60) return 3;
  if (score >= 40) return 2;
  if (score >= 20) return 1;
  return 0;
}
