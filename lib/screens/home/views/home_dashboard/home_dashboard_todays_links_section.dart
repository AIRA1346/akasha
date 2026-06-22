import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../utils/work_link_neighbors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

/// 링크 인덱스 기반 실제 연결 하이라이트 (최대 3건).
class HomeDashboardTodaysLinksSection extends StatefulWidget {
  const HomeDashboardTodaysLinksSection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onOpenWork,
    required this.onOpenEntity,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;

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
    if (oldWidget.vaultItems != widget.vaultItems) {
      _future = _load();
    }
  }

  Future<List<_LinkHighlight>> _load() async {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    final highlights = <_LinkHighlight>[];

    final sorted = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    for (final work in sorted) {
      if (highlights.length >= 3) break;
      final neighbors = await fetchWorkLinkNeighbors(
        work: work,
        userCatalog: widget.userCatalog,
        discovery: discovery,
        linkIndex: widget.linkIndex,
        vaultItems: widget.vaultItems,
      );
      for (final person in neighbors.characters) {
        if (highlights.length >= 3) break;
        highlights.add(_LinkHighlight(work: work, entity: person));
      }
      for (final connected in neighbors.connectedWorks) {
        if (highlights.length >= 3) break;
        highlights.add(_LinkHighlight(work: work, connectedWork: connected));
      }
    }
    return highlights;
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
                  '[[wiki]] 링크로 연결된 작품·인물이 여기에 표시됩니다.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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

class _LinkHighlight {
  const _LinkHighlight({
    required this.work,
    this.entity,
    this.connectedWork,
  });

  final AkashaItem work;
  final UserCatalogEntity? entity;
  final AkashaItem? connectedWork;
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.highlight,
    required this.onOpenWork,
    required this.onOpenEntity,
  });

  final _LinkHighlight highlight;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final targetLabel = highlight.entity?.title ?? highlight.connectedWork?.title ?? '';
    final targetType = highlight.entity != null ? '인물' : '작품';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AkashaColors.surfaceCard(),
      child: InkWell(
        onTap: () {
          if (highlight.entity != null) {
            onOpenEntity(highlight.entity!);
          } else if (highlight.connectedWork != null) {
            onOpenWork(highlight.connectedWork!);
          } else {
            onOpenWork(highlight.work);
          }
        },
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
            const Icon(Icons.arrow_forward_rounded,
                size: 14, color: AkashaColors.accent),
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
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
