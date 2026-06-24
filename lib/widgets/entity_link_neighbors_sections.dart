import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_colors.dart';
import '../utils/entity_link_neighbors.dart';
import 'work_link_neighbors_sections.dart';

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

    final titleStyle = sectionTitleStyle ?? _defaultSectionTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (neighbors.incomingLinkCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.link, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  '이 엔티티를 가리키는 기록 ${neighbors.incomingLinkCount}건',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
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
                  onOpenWork: onOpenWork,
                ),
        ),
        _section(
          title: '연결된 인물',
          isEmpty: neighbors.persons.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.person),
          addLabel: '인물 추가',
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
          title: '관련 사건',
          isEmpty: neighbors.events.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.event),
          addLabel: '사건 추가',
          child: neighbors.events.isEmpty
              ? null
              : _EntityChipList(
                  entities: neighbors.events,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          title: '관련 개념',
          isEmpty: neighbors.concepts.isEmpty && entityTags.isEmpty,
          titleStyle: titleStyle,
          onAdd: onAddEntity == null
              ? null
              : () => onAddEntity!(EntityAnchorType.concept),
          addLabel: '개념 추가',
          child: neighbors.concepts.isEmpty && entityTags.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (neighbors.concepts.isNotEmpty)
                      _EntityChipList(
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
                            .map((t) => _ConceptTagChip(label: t))
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
              : _EntityChipList(
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
              : _EntityChipList(
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
    if (!showEmptySections && isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: titleStyle)),
              if (onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(
                    addLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AkashaColors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            _EmptySectionHint(
              message: '아직 $title 연결이 없습니다.',
              onOpenRecord: onRecordCta,
            )
          else
            child!,
        ],
      ),
    );
  }

  static const _defaultSectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({
    required this.message,
    this.onOpenRecord,
  });

  final String message;
  final VoidCallback? onOpenRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
    );
  }
}

class _EntityChipList extends StatelessWidget {
  const _EntityChipList({
    required this.entities,
    this.onOpenEntity,
  });

  final List<UserCatalogEntity> entities;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entities.map((entity) {
        return ActionChip(
          label: Text(
            entity.title,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: AkashaColors.surface,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          visualDensity: VisualDensity.compact,
          onPressed:
              onOpenEntity == null ? null : () => onOpenEntity!(entity),
        );
      }).toList(),
    );
  }
}

class _ConceptTagChip extends StatelessWidget {
  const _ConceptTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
      ),
    );
  }
}
