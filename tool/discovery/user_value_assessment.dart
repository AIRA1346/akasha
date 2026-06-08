/// Discovery User Value — Prioritization (필터가 아님).
///
/// 질문: "이 작품을 지금 Registry에 넣는 것이 AKASHA 사용자에게 실제로 가치가 있는가?"
library;

import '../registry_v3_utils.dart';
import 'shadow_write_runner.dart';

enum UserValueTier { high, medium, low }

class UserValueAssessment {
  final UserValueTier tier;
  final int score;
  final List<String> highSignals;
  final List<String> lowSignals;
  final String prioritizationNote;

  const UserValueAssessment({
    required this.tier,
    required this.score,
    required this.highSignals,
    required this.lowSignals,
    required this.prioritizationNote,
  });

  static const reviewQuestion =
      '이 작품을 지금 Registry에 넣는 것이 AKASHA 사용자에게 실제로 가치가 있는가?';

  Map<String, dynamic> toJson() => {
        'question': reviewQuestion,
        'tier': tier.name,
        'score': score,
        'highSignals': highSignals,
        'lowSignals': lowSignals,
        'prioritizationNote': prioritizationNote,
      };
}

UserValueAssessment assessUserValue({
  required Map<String, dynamic> draft,
  required ShadowWriteItem item,
  required bool titleDistinctInRegistry,
  required int searchTokenCount,
}) {
  final highSignals = <String>[];
  final lowSignals = <String>[];
  var score = 0;

  final title = draft['title']?.toString().trim() ?? '';
  final creator = draft['creator']?.toString().trim() ?? '';
  final titles = parseTitlesJson(draft['titles']);
  final aliases = (draft['aliases'] as List?)
          ?.map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];
  final year = draft['releaseYear'] is int
      ? draft['releaseYear'] as int
      : int.tryParse(draft['releaseYear']?.toString() ?? '');
  final quality = item.qualityScore ?? 0;

  // --- High signals (Discovery Prioritization) ---
  if (titleDistinctInRegistry) {
    score += 3;
    highSignals.add('검색 Gap 해소 — Registry에 동일 작품 없음');
  }

  if (creator.isNotEmpty) {
    score += 1;
    highSignals.add('creator/studio 존재 — Core·장르 대표작 후보');
  }

  if (titles.length >= 2) {
    score += 1;
    highSignals.add('다국어 titles — 인지도·검색 커버리지');
  }

  if (aliases.length >= 2) {
    score += 1;
    highSignals.add('aliases 풍부 — Core 작품·대중 인지 신호');
  }

  if (year != null && year >= 1980 && year <= 2026) {
    score += 1;
    highSignals.add('releaseYear=$year — 식별·검색 앵커 확보');
  }

  if (quality >= 55) {
    score += 1;
    highSignals.add('qualityScore=$quality — Minimal Core 충실');
  }

  // Franchise 완성도: 동일 creator의 Registry 인접 작품은 수동 리뷰 힌트
  if (creator.isNotEmpty && titleDistinctInRegistry) {
    highSignals.add('Franchise/시리즈 확장 여지 — 수동 확인 권장');
  }

  // --- Low signals ---
  if (creator.isEmpty && aliases.isEmpty && titles.length <= 1) {
    score -= 3;
    lowSignals.add('정보 부족 — 1회성·단편·희귀 작품 가능성');
  }

  if (searchTokenCount < 3) {
    score -= 2;
    lowSignals.add('searchTokens 빈약 — 검색 수요 낮을 것으로 예상');
  }

  if (title.length < 5) {
    score -= 1;
    lowSignals.add('제목 짧음 — 희귀 단편·식별 어려움');
  }

  if (!titleDistinctInRegistry) {
    score -= 2;
    lowSignals.add('Registry 유사 항목 존재 — 검색 Gap 낮음');
  }

  if (year == null) {
    score -= 1;
    lowSignals.add('releaseYear 없음 — 사용자 맥락 부족');
  }

  final tier = _tierFromScore(score);
  final note = switch (tier) {
    UserValueTier.high =>
      '우선 순위 높음 — Trial Write·순증 큐 후보 (Discovery Prioritization)',
    UserValueTier.medium =>
      '중간 우선순위 — 배치 등록 전 수동 확인 권장',
    UserValueTier.low =>
      '후순위 — 등록 가능하나 지금 넣을 가치는 낮을 수 있음 (필터 아님)',
  };

  return UserValueAssessment(
    tier: tier,
    score: score,
    highSignals: highSignals,
    lowSignals: lowSignals,
    prioritizationNote: note,
  );
}

UserValueTier _tierFromScore(int score) {
  if (score >= 5) return UserValueTier.high;
  if (score >= 2) return UserValueTier.medium;
  return UserValueTier.low;
}

Map<String, int> summarizeUserValueTiers(
  Iterable<UserValueAssessment> assessments,
) {
  final counts = <String, int>{
    UserValueTier.high.name: 0,
    UserValueTier.medium.name: 0,
    UserValueTier.low.name: 0,
  };
  for (final a in assessments) {
    counts[a.tier.name] = (counts[a.tier.name] ?? 0) + 1;
  }
  return counts;
}
