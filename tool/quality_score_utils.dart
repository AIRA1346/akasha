/// 작품 품질 신호(원본) → qualityScore / qualityTier (빌드 시 파생)
///
/// - shard에는 [qualitySignals]만 저장 (tier·score 저장 금지)
/// - registry_builder가 search_index에 score·tier 복사
library;

const qualityDescriptionMinChars = 40;

/// 점수 가중치 (총 100)
const qualityWeightTitle = 20;
const qualityWeightYear = 10;
const qualityWeightCreator = 10;
const qualityWeightPoster = 10;
const qualityWeightDescription = 10;
const qualityWeightExternalId = 20;
const qualityWeightVerificationEach = 5;

/// 검증 신호 4종 × 5점 = 20
const qualityVerifiedSignalKeys = [
  'posterVerified',
  'externalIdVerified',
  'descriptionVerified',
  'franchiseVerified',
];

class QualitySignals {
  final bool hasPoster;
  final bool hasDescription;
  final bool posterVerified;
  final bool externalIdVerified;
  final bool descriptionVerified;
  final bool franchiseVerified;

  const QualitySignals({
    this.hasPoster = false,
    this.hasDescription = false,
    this.posterVerified = false,
    this.externalIdVerified = false,
    this.descriptionVerified = false,
    this.franchiseVerified = false,
  });

  Map<String, bool> toJson() => {
        'hasPoster': hasPoster,
        'hasDescription': hasDescription,
        'posterVerified': posterVerified,
        'externalIdVerified': externalIdVerified,
        'descriptionVerified': descriptionVerified,
        'franchiseVerified': franchiseVerified,
      };

  static QualitySignals fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QualitySignals();
    bool flag(String key) => json[key] == true;
    return QualitySignals(
      hasPoster: flag('hasPoster'),
      hasDescription: flag('hasDescription'),
      posterVerified: flag('posterVerified'),
      externalIdVerified: flag('externalIdVerified'),
      descriptionVerified: flag('descriptionVerified'),
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

  final extensions = work['extensions'] is Map
      ? Map<String, dynamic>.from(work['extensions'] as Map)
      : <String, dynamic>{};

  final poster = work['posterPath']?.toString() ?? '';
  final description = work['description']?.toString() ?? '';
  final creator = work['creator']?.toString() ?? '';
  final title = work['title']?.toString() ?? '';
  final titles = work['titles'];
  final hasTitle =
      title.isNotEmpty || (titles is Map && titles.isNotEmpty);

  final hasPoster = storedMap['hasPoster'] == true ||
      (poster.isNotEmpty && poster.startsWith('http'));

  final hasDescription = storedMap['hasDescription'] == true ||
      description.trim().length >= qualityDescriptionMinChars;

  final hasExternalId = _hasExternalId(work);

  final posterVerified = storedMap['posterVerified'] == true ||
      extensions['posterVerified'] == true;

  final externalIdVerified =
      storedMap['externalIdVerified'] == true && hasExternalId;

  final descriptionVerified =
      storedMap['descriptionVerified'] == true && hasDescription;

  final franchiseVerified =
      storedMap['franchiseVerified'] == true || franchiseMember;

  // hasTitle은 점수 계산에 직접 사용 (신호 객체에는 미포함)
  return QualitySignals(
    hasPoster: hasPoster && hasTitle,
    hasDescription: hasDescription && hasTitle,
    posterVerified: posterVerified,
    externalIdVerified: externalIdVerified,
    descriptionVerified: descriptionVerified,
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

  if (signals.hasPoster) score += qualityWeightPoster;
  if (signals.hasDescription) score += qualityWeightDescription;
  if (_hasExternalId(work)) score += qualityWeightExternalId;

  if (signals.posterVerified) {
    score += qualityWeightVerificationEach;
  }
  if (signals.externalIdVerified) {
    score += qualityWeightVerificationEach;
  }
  if (signals.descriptionVerified) {
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
