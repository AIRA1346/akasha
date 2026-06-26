import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_typography.dart';
import '../utils/work_link_neighbors.dart';
import 'link_neighbors_section_chrome.dart';
import 'work_link_character_layouts.dart';
import 'work_link_connected_works_list.dart';
import 'work_preview_theme_clusters_section.dart';

/// 작품·프리뷰·워크벤치 공통 — 링크 이웃 섹션 (연결 우선 UX).
class WorkLinkNeighborsSections extends StatelessWidget {
  const WorkLinkNeighborsSections({
    super.key,
    required this.neighbors,
    this.loading = false,
    this.conceptTags = const [],
    this.onOpenEntity,
    this.onOpenWork,
    this.onLinkCta,
    this.onOpenConcept,
    this.characterTitleStyle,
    this.sectionTitleStyle,
    this.showEmptySections = true,
    this.sourceWork,
    this.workbenchLayout = false,
    this.onAddEntity,
    this.onAddWork,
  });

  final WorkLinkNeighbors neighbors;
  final bool loading;
  final List<String> conceptTags;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final VoidCallback? onLinkCta;
  final void Function(UserCatalogEntity entity)? onOpenConcept;
  final TextStyle? characterTitleStyle;
  final TextStyle? sectionTitleStyle;
  final bool showEmptySections;
  final AkashaItem? sourceWork;
  final bool workbenchLayout;
  final void Function(EntityAnchorType type)? onAddEntity;
  final VoidCallback? onAddWork;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final titleStyle = sectionTitleStyle ?? _defaultSectionTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          title: '주요 인물',
          isEmpty: neighbors.characters.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.person),
          addLabel: '인물 추가',
          child: neighbors.characters.isEmpty
              ? null
              : workbenchLayout
                  ? WorkLinkCharacterWorkbenchList(
                      characters: neighbors.characters,
                      onOpenEntity: onOpenEntity,
                    )
                  : WorkLinkCharacterRow(
                      characters: neighbors.characters,
                      onOpenEntity: onOpenEntity,
                    ),
        ),
        _section(
          title: '연결된 작품',
          isEmpty: neighbors.connectedWorks.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddWork,
          addLabel: '작품 추가',
          child: neighbors.connectedWorks.isEmpty
              ? null
              : WorkLinkConnectedWorksList(
                  works: neighbors.connectedWorks,
                  bridgeLabelsByWorkId: neighbors.connectedWorkBridgeLabels,
                  sourceWork: sourceWork,
                  onOpenWork: onOpenWork,
                ),
        ),
        if (neighbors.themeClusters.isNotEmpty)
          WorkPreviewThemeClustersSection(
            clusters: neighbors.themeClusters,
            onOpenConcept: onOpenConcept == null
                ? null
                : (cluster) => onOpenConcept!(cluster.concept),
          ),
        _section(
          title: '관련 사건',
          isEmpty: neighbors.events.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.event),
          addLabel: '사건 추가',
          child: neighbors.events.isEmpty
              ? null
              : LinkNeighborsEntityChipList(
                  entities: neighbors.events,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          title: '관련 개념',
          isEmpty: neighbors.concepts.isEmpty && conceptTags.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.concept),
          addLabel: '개념 추가',
          child: neighbors.concepts.isEmpty && conceptTags.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (neighbors.concepts.isNotEmpty)
                      LinkNeighborsEntityChipList(
                        entities: neighbors.concepts,
                        onOpenEntity: onOpenEntity,
                      ),
                    if (conceptTags.isNotEmpty) ...[
                      if (neighbors.concepts.isNotEmpty)
                        const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: conceptTags
                            .map((tag) => LinkNeighborsConceptTagChip(label: tag))
                            .toList(),
                      ),
                    ],
                  ],
                ),
        ),
        _section(
          title: '관련 장소',
          isEmpty: neighbors.places.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.place),
          addLabel: '장소 추가',
          child: neighbors.places.isEmpty
              ? null
              : LinkNeighborsEntityChipList(
                  entities: neighbors.places,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          title: '관련 조직',
          isEmpty: neighbors.organizations.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.organization),
          addLabel: '조직 추가',
          child: neighbors.organizations.isEmpty
              ? null
              : LinkNeighborsEntityChipList(
                  entities: neighbors.organizations,
                  onOpenEntity: onOpenEntity,
                ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required bool isEmpty,
    required TextStyle titleStyle,
    Widget? child,
    VoidCallback? onAdd,
    String addLabel = '추가',
  }) {
    return LinkNeighborsSection(
      title: title,
      isEmpty: isEmpty,
      titleStyle: titleStyle,
      showEmptySections: showEmptySections,
      onAdd: onAdd,
      addLabel: addLabel,
      emptyChild: LinkNeighborsEmptyLinkCta(
        message: '아직 $title 연결이 없습니다.',
        onPressed: onLinkCta,
      ),
      child: child,
    );
  }

  static final _defaultSectionTitle = AkashaTypography.sectionTitle;
}
