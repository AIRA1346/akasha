import '../models/akasha_item.dart';

/// 작품·엔티티 탐색 깊이를 0.0~1.0으로 추정합니다 (기록·태그·본문 기반 휴리스틱).
double explorationProgress(AkashaItem item) {
  var score = 0.12;

  final reviewLen = item.review.trim().length;
  if (reviewLen > 0) {
    score += 0.28 + (reviewLen.clamp(0, 800) / 800) * 0.12;
  }

  final bodyLen = item.bodyRaw.trim().length;
  if (bodyLen > 80) {
    score += 0.18 + (bodyLen.clamp(0, 1200) / 1200) * 0.1;
  }

  if (item.tags.isNotEmpty) {
    score += 0.08 + (item.tags.length.clamp(1, 4) - 1) * 0.04;
  }

  if (item.rating > 0) score += 0.08;
  if (item.memorableQuotes.isNotEmpty) score += 0.06;
  if (item.description.trim().isNotEmpty) score += 0.04;

  return score.clamp(0.08, 1.0);
}

int explorationProgressPercent(AkashaItem item) =>
    (explorationProgress(item) * 100).round();
