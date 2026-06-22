import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_colors.dart';
import '../utils/work_link_neighbors.dart';
import 'poster_image.dart';

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
    this.characterTitleStyle,
    this.sectionTitleStyle,
    this.showEmptySections = true,
  });

  final WorkLinkNeighbors neighbors;
  final bool loading;
  final List<String> conceptTags;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final VoidCallback? onLinkCta;
  final TextStyle? characterTitleStyle;
  final TextStyle? sectionTitleStyle;
  final bool showEmptySections;

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
          child: neighbors.characters.isEmpty
              ? null
              : WorkLinkCharacterRow(
                  characters: neighbors.characters,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          title: '연결된 작품',
          isEmpty: neighbors.connectedWorks.isEmpty,
          titleStyle: titleStyle,
          child: neighbors.connectedWorks.isEmpty
              ? null
              : WorkLinkConnectedWorksList(
                  works: neighbors.connectedWorks,
                  onOpenWork: onOpenWork,
                ),
        ),
        _section(
          title: '관련 사건',
          isEmpty: neighbors.events.isEmpty,
          titleStyle: titleStyle,
          child: neighbors.events.isEmpty
              ? null
              : _EntityChipList(
                  entities: neighbors.events,
                  onOpenEntity: onOpenEntity,
                ),
        ),
        _section(
          title: '관련 개념',
          isEmpty: neighbors.concepts.isEmpty && conceptTags.isEmpty,
          titleStyle: titleStyle,
          child: neighbors.concepts.isEmpty && conceptTags.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (neighbors.concepts.isNotEmpty)
                      _EntityChipList(
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
                            .map((tag) => _ConceptTagChip(label: tag))
                            .toList(),
                      ),
                    ],
                  ],
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
  }) {
    if (!showEmptySections && isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          if (isEmpty)
            _EmptyLinkCta(
              message: '아직 $title 연결이 없습니다.',
              onPressed: onLinkCta,
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

class _EmptyLinkCta extends StatelessWidget {
  const _EmptyLinkCta({
    required this.message,
    this.onPressed,
  });

  final String message;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          if (onPressed != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '본문에서 [[링크]] 추가하기',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
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

class WorkLinkCharacterRow extends StatelessWidget {
  const WorkLinkCharacterRow({
    super.key,
    required this.characters,
    this.onOpenEntity,
  });

  final List<UserCatalogEntity> characters;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: characters.map((person) {
          final avatarItem = EntityItem(
            entityType: EntityAnchorType.person,
            entityId: person.entityId,
            title: person.title,
            category: person.subtype,
            domain: person.domain,
            creator: person.creator,
            releaseYear: person.releaseYear,
            posterPath: person.posterPath,
            tags: person.tags,
            addedAt: person.addedAt,
          );

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: onOpenEntity == null ? null : () => onOpenEntity!(person),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                child: Column(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WorkLinkConnectedWorksList extends StatelessWidget {
  const WorkLinkConnectedWorksList({
    super.key,
    required this.works,
    this.onOpenWork,
  });

  final List<AkashaItem> works;
  final void Function(AkashaItem work)? onOpenWork;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: works.map((work) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onOpenWork == null ? null : () => onOpenWork!(work),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 28,
                      height: 40,
                      child: PosterImage(item: work, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      work.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AkashaColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      '링크 연결',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
