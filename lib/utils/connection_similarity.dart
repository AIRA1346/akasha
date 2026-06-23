import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../services/relationship_discovery_service.dart';

/// 연결 유사도 축 — Discovery·Preview UI용 휴리스틱 (R15).
enum ConnectionSimilarityAxis {
  narrative,
  character,
  conceptual,
}

extension ConnectionSimilarityAxisX on ConnectionSimilarityAxis {
  String get label => switch (this) {
        ConnectionSimilarityAxis.narrative => '서사 유사도',
        ConnectionSimilarityAxis.character => '인물 유사도',
        ConnectionSimilarityAxis.conceptual => '개념 연결',
      };
}

/// 두 작품 간 유사도 (0–100).
int workPairSimilarityPercent(AkashaItem a, AkashaItem b) {
  if (a.workId == b.workId) return 100;

  var score = 42;

  final commonTags = a.tags.where((t) => b.tags.contains(t)).toList();
  if (commonTags.isNotEmpty) {
    score += 18 + (commonTags.length.clamp(1, 3) - 1) * 6;
  }
  if (a.creator.isNotEmpty && a.creator == b.creator) {
    score += 22;
  }
  if (a.category == b.category) {
    score += 8;
  }
  if (a.domain == b.domain) {
    score += 4;
  }

  return score.clamp(35, 98);
}

/// 브리지 종류 → 유사도 축·%.
({ConnectionSimilarityAxis axis, int percent, String label}) bridgeSimilarity({
  required WorkConnectionBridgeKind kind,
  String? entityTitle,
  AkashaItem? source,
  AkashaItem? target,
}) {
  final base = switch (kind) {
    WorkConnectionBridgeKind.sharedPerson => (
        ConnectionSimilarityAxis.character,
        78,
        entityTitle != null ? '인물 · $entityTitle' : '공유 인물',
      ),
    WorkConnectionBridgeKind.sharedConcept => (
        ConnectionSimilarityAxis.conceptual,
        85,
        entityTitle != null ? '개념 · $entityTitle' : '공유 개념',
      ),
    WorkConnectionBridgeKind.sharedEvent => (
        ConnectionSimilarityAxis.narrative,
        72,
        entityTitle != null ? '사건 · $entityTitle' : '공유 사건',
      ),
    WorkConnectionBridgeKind.sharedPlace => (
        ConnectionSimilarityAxis.narrative,
        68,
        entityTitle != null ? '장소 · $entityTitle' : '공유 장소',
      ),
    WorkConnectionBridgeKind.sharedOrganization => (
        ConnectionSimilarityAxis.narrative,
        70,
        entityTitle != null ? '조직 · $entityTitle' : '공유 조직',
      ),
    WorkConnectionBridgeKind.directWorkLink => (
        ConnectionSimilarityAxis.narrative,
        88,
        '직접 링크',
      ),
  };

  var percent = base.$2;
  if (source != null && target != null) {
    final pair = workPairSimilarityPercent(source, target);
    percent = ((percent + pair) / 2).round();
  }

  return (axis: base.$1, percent: percent.clamp(40, 98), label: base.$3);
}

/// 인물 쌍 (주목할 인물 탭).
int personPairSimilarityPercent(
  UserCatalogEntity a,
  UserCatalogEntity b,
) {
  if (a.entityId == b.entityId) return 100;
  var score = 55;
  final commonTags = a.tags.where((t) => b.tags.contains(t)).toList();
  if (commonTags.isNotEmpty) {
    score += 20 + (commonTags.length.clamp(1, 2) * 8);
  }
  final commonAliases = a.aliases.where((al) => b.aliases.contains(al)).length;
  if (commonAliases > 0) score += 12;
  return score.clamp(45, 95);
}

/// 브리지 라벨 문자열 → 표시용 % 라벨.
String similarityBadgeLabel({
  required ConnectionSimilarityAxis axis,
  required int percent,
}) =>
    '${axis.label} $percent%';
