import 'package:flutter/material.dart';

import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../services/relationship_discovery_service.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../utils/connection_similarity.dart';
import '../../../../utils/work_link_neighbors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

/// 발견의 여정 — 추천 연결·새 작품·주목 인물. v1: [FeatureFlags.showDiscoveryHome].
class HomeDashboardDiscoverySection extends StatefulWidget {
  const HomeDashboardDiscoverySection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onItemTap,
    this.onItemDoubleTap,
    required this.onOpenEntity,
    this.onOpenEntityDetail,
    required this.onGoExplore,
    required this.onSearch,
    this.onConnectSuggested,
    this.onOpenRecord,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(UserCatalogEntity entity)? onOpenEntityDetail;
  final VoidCallback onGoExplore;
  final VoidCallback onSearch;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;
  final void Function(AkashaItem work)? onOpenRecord;

  @override
  State<HomeDashboardDiscoverySection> createState() =>
      _HomeDashboardDiscoverySectionState();
}

class _HomeDashboardDiscoverySectionState
    extends State<HomeDashboardDiscoverySection> {
  int _activeTab = 0;
  late Future<_DiscoveryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardDiscoverySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _future = _load();
    }
  }

  Future<_DiscoveryData> _load() async {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );

    final pairs = <_PairHighlight>[];
    final sorted = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    for (final work in sorted) {
      if (pairs.length >= 3) break;
      final neighbors = await fetchWorkLinkNeighbors(
        work: work,
        userCatalog: widget.userCatalog,
        discovery: discovery,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
        connectedWorkLimit: 1,
      );

      if (neighbors.connectedWorks.isNotEmpty) {
        final connected = neighbors.connectedWorks.first;
        final bridgeLabel = neighbors.connectedWorkBridgeLabels[connected.workId];
        WorkConnectionBridgeKind? kind;
        if (bridgeLabel != null) {
          kind = _inferKind(bridgeLabel);
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
          _PairHighlight(
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
        userCatalog: widget.userCatalog,
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
        _PairHighlight.suggestion(
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
          _PairHighlight(
            left: a,
            right: b,
            axis: ConnectionSimilarityAxis.narrative,
            percent: workPairSimilarityPercent(a, b),
          ),
        );
      }
    }

    final persons = widget.userCatalog.all
        .where((e) => e.anchorType == EntityAnchorType.person)
        .toList();

    return _DiscoveryData(pairs: pairs, persons: persons);
  }

  WorkConnectionBridgeKind _inferKind(String label) {
    if (label.contains('인물')) return WorkConnectionBridgeKind.sharedPerson;
    if (label.contains('개념')) return WorkConnectionBridgeKind.sharedConcept;
    if (label.contains('사건')) return WorkConnectionBridgeKind.sharedEvent;
    if (label.contains('장소')) return WorkConnectionBridgeKind.sharedPlace;
    if (label.contains('조직')) return WorkConnectionBridgeKind.sharedOrganization;
    if (label.contains('직접')) return WorkConnectionBridgeKind.directWorkLink;
    return WorkConnectionBridgeKind.sharedConcept;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HomeDashboardStyles.sectionHeader('발견의 여정'),
            const Spacer(),
            _TabButton(
              label: '추천 연결',
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            _TabButton(
              label: '새로운 작품',
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
            _TabButton(
              label: '주목할 인물',
              isActive: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<_DiscoveryData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final data = snapshot.data ?? const _DiscoveryData();
            return Column(
              children: [
                Row(children: _buildContent(data)),
                if (_activeTab == 0 && data.pairs.isEmpty) ...[
                  const SizedBox(height: 12),
                  _EmptyCta(
                    message: '기록에 [[링크]]를 추가하면 추천 연결이 여기에 표시됩니다.',
                    primaryLabel: '작품 검색',
                    onPrimary: widget.onSearch,
                    secondaryLabel: widget.onOpenRecord != null ? '기록하기' : null,
                    onSecondary: data.pairs.isEmpty && widget.vaultItems.isNotEmpty
                        ? () => widget.onOpenRecord?.call(widget.vaultItems.first)
                        : null,
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.onGoExplore,
            child: const Text(
              '더 많은 연결 보기',
              style: TextStyle(
                fontSize: 12,
                color: AkashaColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent(_DiscoveryData data) {
    if (widget.vaultItems.isEmpty) {
      return [
        Expanded(
          child: _EmptyCta(
            message: '볼트에 작품을 추가하면 발견의 여정이 시작됩니다.',
            primaryLabel: '작품 검색',
            onPrimary: widget.onSearch,
          ),
        ),
      ];
    }

    if (_activeTab == 0) {
      if (data.pairs.isEmpty) {
        return const [Expanded(child: SizedBox(height: 8))];
      }
      return data.pairs.take(3).map((pair) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PairCard(
              highlight: pair,
              onItemTap: widget.onItemTap,
              onItemDoubleTap: widget.onItemDoubleTap,
              onOpenEntity: widget.onOpenEntity,
              onConnectSuggested: widget.onConnectSuggested,
            ),
          ),
        );
      }).toList();
    }

    if (_activeTab == 1) {
      final sorted = List<AkashaItem>.from(widget.vaultItems)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      final items = sorted.take(3).toList();
      if (items.isEmpty) {
        return const [
          Expanded(
            child: Center(
              child: Text(
                '최근 추가한 작품이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ];
      }
      return items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SingleCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              onDoubleTap: widget.onItemDoubleTap == null
                  ? null
                  : () => widget.onItemDoubleTap!(item),
            ),
          ),
        );
      }).toList();
    }

    if (data.persons.isEmpty) {
      return [
        Expanded(
          child: _EmptyCta(
            message: '등록된 인물이 없습니다. 인물을 추가하고 작품과 연결해 보세요.',
            primaryLabel: '인물 탐색',
            onPrimary: widget.onGoExplore,
          ),
        ),
      ];
    }

    return data.persons.take(3).map((person) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _EntityCard(
            entity: person,
            onTap: () => widget.onOpenEntity(person),
            onDoubleTap: widget.onOpenEntityDetail == null
                ? null
                : () => widget.onOpenEntityDetail!(person),
          ),
        ),
      );
    }).toList();
  }
}

class _DiscoveryData {
  const _DiscoveryData({
    this.pairs = const [],
    this.persons = const [],
  });

  final List<_PairHighlight> pairs;
  final List<UserCatalogEntity> persons;
}

class _PairHighlight {
  const _PairHighlight({
    required this.left,
    required this.right,
    required this.axis,
    required this.percent,
    this.candidate,
  });

  factory _PairHighlight.suggestion({
    required AkashaItem work,
    required LinkCandidate candidate,
    required ConnectionSimilarityAxis axis,
    required int percent,
  }) {
    return _PairHighlight(
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

class _EmptyCta extends StatelessWidget {
  const _EmptyCta({
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: AkashaColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: Text(primaryLabel, style: const TextStyle(fontSize: 11)),
              ),
              if (secondaryLabel != null && onSecondary != null)
                OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.grey[600],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({
    required this.highlight,
    required this.onItemTap,
    this.onItemDoubleTap,
    required this.onOpenEntity,
    this.onConnectSuggested,
  });

  final _PairHighlight highlight;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;

  @override
  Widget build(BuildContext context) {
    final badge = similarityBadgeLabel(
      axis: highlight.axis,
      percent: highlight.percent,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            badge,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AkashaColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WorkThumb(
                  item: highlight.left,
                  onTap: () => onItemTap(highlight.left),
                  onDoubleTap: onItemDoubleTap == null
                      ? null
                      : () => onItemDoubleTap!(highlight.left),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AkashaColors.accent,
                  ),
                ),
                if (highlight.isSuggestion)
                  _SuggestionThumb(
                    candidate: highlight.candidate!,
                    onTap: onConnectSuggested == null
                        ? null
                        : () => onConnectSuggested!(
                              highlight.candidate!,
                              highlight.left,
                            ),
                  )
                else
                  _WorkThumb(
                    item: highlight.right,
                    onTap: () => onItemTap(highlight.right),
                    onDoubleTap: onItemDoubleTap == null
                        ? null
                        : () => onItemDoubleTap!(highlight.right),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionThumb extends StatelessWidget {
  const _SuggestionThumb({required this.candidate, this.onTap});

  final LinkCandidate candidate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AkashaColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AkashaColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.add_link_rounded,
                color: AkashaColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                candidate.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleCard extends StatelessWidget {
  const _SingleCard({
    required this.item,
    required this.onTap,
    this.onDoubleTap,
  });

  final AkashaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AkashaColors.newBadgeText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _WorkThumb(item: item, onTap: onTap),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entity,
    required this.onTap,
    this.onDoubleTap,
  });

  final UserCatalogEntity entity;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final avatarItem = EntityItem(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      category: entity.subtype,
      domain: entity.domain,
      creator: entity.creator,
      releaseYear: entity.releaseYear,
      posterPath: entity.posterPath,
      tags: entity.tags,
      addedAt: entity.addedAt,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AkashaColors.surfaceCard(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkThumb extends StatelessWidget {
  const _WorkThumb({
    required this.item,
    required this.onTap,
    this.onDoubleTap,
  });

  final AkashaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: PosterImage(item: item, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
