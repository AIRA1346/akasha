import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../services/relationship_discovery_service.dart';
import '../../../../utils/connection_similarity.dart';
import '../../../../utils/work_link_neighbors.dart';

/// 발견의 여정 — 비동기 로드 결과.
class DiscoverySectionData {
  const DiscoverySectionData({
    this.pairs = const [],
    this.persons = const [],
  });

  final List<DiscoveryPairHighlight> pairs;
  final List<UserCatalogEntity> persons;
}

/// 추천 연결 카드 한 쌍(또는 제안).
class DiscoveryPairHighlight {
  const DiscoveryPairHighlight({
    required this.left,
    required this.right,
    required this.axis,
    required this.percent,
    this.candidate,
  });

  factory DiscoveryPairHighlight.suggestion({
    required AkashaItem work,
    required LinkCandidate candidate,
    required ConnectionSimilarityAxis axis,
    required int percent,
  }) {
    return DiscoveryPairHighlight(
      left: work,
      right: work,
      axis: axis,
      percent: percent,
      candidate: candidate,
    );
  }

  final AkashaItem left;
  final AkashaItem right;
  final ConnectionSimilarityAxis axis;
  final int percent;
  final LinkCandidate? candidate;

  bool get isSuggestion => candidate != null;
  AkashaItem? get rightWork => isSuggestion ? null : right;
}

WorkConnectionBridgeKind inferDiscoveryBridgeKind(String label) {
  if (label.contains('인물')) return WorkConnectionBridgeKind.sharedPerson;
  if (label.contains('개념')) return WorkConnectionBridgeKind.sharedConcept;
  if (label.contains('사건')) return WorkConnectionBridgeKind.sharedEvent;
  if (label.contains('장소')) return WorkConnectionBridgeKind.sharedPlace;
  if (label.contains('조직')) return WorkConnectionBridgeKind.sharedOrganization;
  if (label.contains('직접')) return WorkConnectionBridgeKind.directWorkLink;
  return WorkConnectionBridgeKind.sharedConcept;
}

Future<DiscoverySectionData> loadDiscoverySectionData({
  required List<AkashaItem> vaultItems,
  required UserCatalogPort userCatalog,
  required RecordLinkPort linkIndex,
}) async {
  final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
    linkIndex: linkIndex,
    vaultItems: vaultItems,
  );

  final pairs = <DiscoveryPairHighlight>[];
  final sorted = List<AkashaItem>.from(vaultItems)
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  for (final work in sorted) {
    if (pairs.length >= 3) break;
    final neighbors = await fetchWorkLinkNeighbors(
      work: work,
      userCatalog: userCatalog,
      discovery: discovery,
      linkIndex: linkIndex,
      vaultItems: vaultItems,
      connectedWorkLimit: 1,
    );

    if (neighbors.connectedWorks.isNotEmpty) {
      final connected = neighbors.connectedWorks.first;
      final bridgeLabel = neighbors.connectedWorkBridgeLabels[connected.workId];
      WorkConnectionBridgeKind? kind;
      if (bridgeLabel != null) {
        kind = inferDiscoveryBridgeKind(bridgeLabel);
      }
      final sim = kind != null
          ? bridgeSimilarity(
              kind: kind,
              source: work,
              target: connected,
            )
          : (
              axis: ConnectionSimilarityAxis.narrative,
              percent: workPairSimilarityPercent(work, connected),
              label: '연결 탐색',
            );
      pairs.add(
        DiscoveryPairHighlight(
          left: work,
          right: connected,
          axis: sim.axis,
          percent: sim.percent,
        ),
      );
      continue;
    }

    final candidates = await LinkCandidateService.candidatesForWork(
      work: work,
      userCatalog: userCatalog,
      limit: 1,
    );
    if (candidates.isEmpty) continue;

    final candidate = candidates.first;
    final axis = switch (candidate.anchorType) {
      EntityAnchorType.person => ConnectionSimilarityAxis.character,
      EntityAnchorType.concept => ConnectionSimilarityAxis.conceptual,
      _ => ConnectionSimilarityAxis.narrative,
    };
    pairs.add(
      DiscoveryPairHighlight.suggestion(
        work: work,
        candidate: candidate,
        axis: axis,
        percent: 62,
      ),
    );
  }

  if (pairs.length < 3 && sorted.length >= 2) {
    for (var i = 0; i < sorted.length - 1 && pairs.length < 3; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final exists = pairs.any(
        (p) =>
            (p.left.workId == a.workId && p.rightWork?.workId == b.workId) ||
            (p.left.workId == b.workId && p.rightWork?.workId == a.workId),
      );
      if (exists) continue;
      pairs.add(
        DiscoveryPairHighlight(
          left: a,
          right: b,
          axis: ConnectionSimilarityAxis.narrative,
          percent: workPairSimilarityPercent(a, b),
        ),
      );
    }
  }

  final persons = userCatalog.all
      .where((e) => e.anchorType == EntityAnchorType.person)
      .toList();

  return DiscoverySectionData(pairs: pairs, persons: persons);
}
