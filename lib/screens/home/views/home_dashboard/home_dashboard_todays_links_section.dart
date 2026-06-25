import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../utils/work_link_neighbors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

/// 링크 인덱스 기반 Discovery 하이라이트 (최대 3건 · R8 P2-A).
class HomeDashboardTodaysLinksSection extends StatefulWidget {
  const HomeDashboardTodaysLinksSection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onOpenWork,
    required this.onOpenEntity,
    this.onConnectSuggested,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;

  @override
  State<HomeDashboardTodaysLinksSection> createState() =>
      _HomeDashboardTodaysLinksSectionState();
}

class _HomeDashboardTodaysLinksSectionState
    extends State<HomeDashboardTodaysLinksSection> {
  late Future<List<_LinkHighlight>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardTodaysLinksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _future = _load();
    }
  }

  Future<List<_LinkHighlight>> _load() async {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    final highlights = <_LinkHighlight>[];

    final linkCounts = <String, int>{};
    for (final work in widget.vaultItems) {
      if (work.workId.isEmpty) continue;
      linkCounts[work.workId] =
          (await discovery.entityIdsForWork(work.workId)).length;
    }

    final sorted = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) {
        final la = linkCounts[a.workId] ?? 0;
        final lb = linkCounts[b.workId] ?? 0;
        if (la != lb) return lb.compareTo(la);
        return b.addedAt.compareTo(a.addedAt);
      });

    for (final work in sorted) {
      if (highlights.length >= 3) break;

      final linkCount = linkCounts[work.workId] ?? 0;
      if (linkCount == 0) {
        final candidates = await LinkCandidateService.candidatesForWork(
          work: work,
          userCatalog: widget.userCatalog,
          limit: 1,
        );
        if (candidates.isNotEmpty) {
          highlights.add(
            _LinkHighlight.suggestion(work: work, candidate: candidates.first),
          );
        }
        continue;
      }

      final neighbors = await fetchWorkLinkNeighbors(
        work: work,
        userCatalog: widget.userCatalog,
        discovery: discovery,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      );

      _appendFromNeighbors(highlights, work: work, neighbors: neighbors);
    }

    return highlights.take(3).toList();
  }

  void _appendFromNeighbors(
    List<_LinkHighlight> highlights, {
    required AkashaItem work,
    required WorkLinkNeighbors neighbors,
  }) {
    for (final person in neighbors.characters) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.entity(
          work: work,
          entity: person,
          relationLabel: '인물',
        ),
      );
    }
    for (final connected in neighbors.connectedWorks) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.connectedWork(work: work, connectedWork: connected),
      );
    }
    for (final event in neighbors.events) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.entity(work: work, entity: event, relationLabel: '사건'),
      );
    }
    for (final concept in neighbors.concepts) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.entity(
          work: work,
          entity: concept,
          relationLabel: '개념',
        ),
      );
    }
    for (final place in neighbors.places) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.entity(
          work: work,
          entity: place,
          relationLabel: '장소',
        ),
      );
    }
    for (final org in neighbors.organizations) {
      if (highlights.length >= 3) return;
      highlights.add(
        _LinkHighlight.entity(
          work: work,
          entity: org,
          relationLabel: '조직',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('오늘의 연결'),
        const SizedBox(height: 12),
        FutureBuilder<List<_LinkHighlight>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 72,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final links = snapshot.data ?? const [];
            if (links.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '기록에서 연결한 작품·인물이 여기에 표시됩니다.',
                  style: TextStyle(fontSize: 11, color: AkashaColors.textMuted),
                ),
              );
            }
            return Row(
              children: links.map((link) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _LinkCard(
                      highlight: link,
                      onOpenWork: widget.onOpenWork,
                      onOpenEntity: widget.onOpenEntity,
                      onConnectSuggested: widget.onConnectSuggested,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

enum _HighlightKind {
  entity,
  connectedWork,
  suggestion,
}

class _LinkHighlight {
  const _LinkHighlight._({
    required this.work,
    required this.kind,
    this.entity,
    this.connectedWork,
    this.candidate,
    this.relationLabel,
  });

  factory _LinkHighlight.entity({
    required AkashaItem work,
    required UserCatalogEntity entity,
    required String relationLabel,
  }) {
    return _LinkHighlight._(
      work: work,
      kind: _HighlightKind.entity,
      entity: entity,
      relationLabel: relationLabel,
    );
  }

  factory _LinkHighlight.connectedWork({
    required AkashaItem work,
    required AkashaItem connectedWork,
  }) {
    return _LinkHighlight._(
      work: work,
      kind: _HighlightKind.connectedWork,
      connectedWork: connectedWork,
      relationLabel: '연결 작품',
    );
  }

  factory _LinkHighlight.suggestion({
    required AkashaItem work,
    required LinkCandidate candidate,
  }) {
    return _LinkHighlight._(
      work: work,
      kind: _HighlightKind.suggestion,
      candidate: candidate,
      relationLabel: '연결 제안',
    );
  }

  final AkashaItem work;
  final _HighlightKind kind;
  final UserCatalogEntity? entity;
  final AkashaItem? connectedWork;
  final LinkCandidate? candidate;
  final String? relationLabel;
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.highlight,
    required this.onOpenWork,
    required this.onOpenEntity,
    this.onConnectSuggested,
  });

  final _LinkHighlight highlight;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;

  @override
  Widget build(BuildContext context) {
    final targetLabel = switch (highlight.kind) {
      _HighlightKind.entity => highlight.entity?.title ?? '',
      _HighlightKind.connectedWork => highlight.connectedWork?.title ?? '',
      _HighlightKind.suggestion => highlight.candidate?.title ?? '',
    };
    final targetType = highlight.relationLabel ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AkashaColors.surfaceCard(),
      child: InkWell(
        onTap: () => _onTap(),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 36,
                child: PosterImage(item: highlight.work, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              highlight.kind == _HighlightKind.suggestion
                  ? Icons.lightbulb_outline
                  : Icons.arrow_forward_rounded,
              size: 14,
              color: AkashaColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.work.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$targetType · $targetLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: AkashaColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap() {
    switch (highlight.kind) {
      case _HighlightKind.entity:
        if (highlight.entity != null) onOpenEntity(highlight.entity!);
      case _HighlightKind.connectedWork:
        if (highlight.connectedWork != null) {
          onOpenWork(highlight.connectedWork!);
        } else {
          onOpenWork(highlight.work);
        }
      case _HighlightKind.suggestion:
        final candidate = highlight.candidate;
        if (candidate != null && onConnectSuggested != null) {
          onConnectSuggested!(candidate, highlight.work);
        } else {
          onOpenWork(highlight.work);
        }
    }
  }
}
