import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_typography.dart';
import '../utils/entity_link_neighbors.dart';
import 'link_neighbors_section_chrome.dart';
import 'work_link_character_layouts.dart';
import 'work_link_connected_works_list.dart';
import '../utils/app_l10n.dart';

/// Entity 프리뷰·워크벤치 공통 — 연결 섹션 (WorkLinkNeighborsSections와 동일 UX).
class EntityLinkNeighborsSections extends StatelessWidget {
  const EntityLinkNeighborsSections({
    super.key,
    required this.neighbors,
    required this.entityTags,
    this.loading = false,
    this.onOpenEntity,
    this.onOpenWork,
    this.onRecordCta,
    this.sectionTitleStyle,
    this.showEmptySections = true,
    this.workbenchLayout = false,
    this.onAddEntity,
    this.onAddWork,
  });

  final EntityLinkNeighbors neighbors;
  final List<String> entityTags;
  final bool loading;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final VoidCallback? onRecordCta;
  final TextStyle? sectionTitleStyle;
  final bool showEmptySections;
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

    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final titleStyle = sectionTitleStyle ?? _defaultSectionTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (neighbors.incomingLinkCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.link, size: 14, color: palette.textMuted),
                const SizedBox(width: 6),
                Text(
                  l10n != null
                      ? l10n.incomingLinkCount(neighbors.incomingLinkCount)
                      : '이 엔티티를 가리키는 기록 ${neighbors.incomingLinkCount}건',
                  style: AkashaTypography.bodySecondary,
                ),
              ],
            ),
          ),
        _section(
          context: context,
          title: l10n?.sectionConnectedWorks ?? '연결된 작품',
          isEmpty: neighbors.connectedWorks.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddWork,
          addLabel: l10n?.addWork ?? '작품 추가',
          child: neighbors.connectedWorks.isEmpty
              ? null
              : WorkLinkConnectedWorksList(
                  works: neighbors.connectedWorks,
                  onOpenWork: onOpenWork,
                ),
        ),
        _section(
          context: context,
          title: l10n?.sectionConnectedPersons ?? '연결된 인물',
          isEmpty: neighbors.persons.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.person),
          addLabel: l10n?.addPerson ?? '인물 추가',
          child: neighbors.persons.isEmpty
              ? null
              : workbenchLayout
              ? WorkLinkCharacterWorkbenchList(
                  characters: neighbors.persons,
                  onOpenEntity: onOpenEntity,
                )
              : WorkLinkCharacterRow(
                  characters: neighbors.persons,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          context: context,
          title: l10n?.sectionConnectedEvents ?? '관련 사건',
          isEmpty: neighbors.events.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.event),
          addLabel: l10n?.addEvent ?? '사건 추가',
          child: neighbors.events.isEmpty
              ? null
              : LinkNeighborsEntityChipList(
                  entities: neighbors.events,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          context: context,
          title: l10n?.sectionConnectedConcepts ?? '관련 개념',
          isEmpty: neighbors.concepts.isEmpty && entityTags.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.concept),
          addLabel: l10n?.addConcept ?? '개념 추가',
          child: neighbors.concepts.isEmpty && entityTags.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (neighbors.concepts.isNotEmpty)
                      LinkNeighborsEntityChipList(
                        entities: neighbors.concepts,
                        onOpenEntity: onOpenEntity,
                      ),
                    if (entityTags.isNotEmpty) ...[
                      if (neighbors.concepts.isNotEmpty)
                        const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entityTags
                            .map((t) => LinkNeighborsConceptTagChip(label: t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
        ),
        _section(
          context: context,
          title: l10n?.sectionConnectedPlaces ?? '관련 장소',
          isEmpty: neighbors.places.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.place),
          addLabel: l10n?.addPlace ?? '장소 추가',
          child: neighbors.places.isEmpty
              ? null
              : LinkNeighborsEntityChipList(
                  entities: neighbors.places,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          context: context,
          title: l10n?.sectionConnectedOrganizations ?? '관련 조직',
          isEmpty: neighbors.organizations.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.organization),
          addLabel: l10n?.addOrganization ?? '조직 추가',
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
    required BuildContext context,
    required String title,
    required bool isEmpty,
    required TextStyle titleStyle,
    Widget? child,
    VoidCallback? onAdd,
    String addLabel = '추가',
  }) {
    final l10n = lookupAppL10n(context);
    return LinkNeighborsSection(
      title: title,
      isEmpty: isEmpty,
      titleStyle: titleStyle,
      showEmptySections: showEmptySections,
      onAdd: onAdd,
      addLabel: addLabel,
      emptyChild: LinkNeighborsEmptyHint(
        message: l10n != null ? l10n.noLinksYet(title) : '아직 $title 연결이 없습니다.',
      ),
      child: child,
    );
  }

  static final _defaultSectionTitle = AkashaTypography.sectionTitle;
}
