import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_colors.dart';
import '../utils/work_link_neighbors.dart';
import 'poster_image.dart';

class WorkLinkNeighborsSections extends StatelessWidget {
  const WorkLinkNeighborsSections({
    super.key,
    required this.neighbors,
    this.loading = false,
    this.onOpenEntity,
    this.onOpenWork,
    this.characterTitleStyle,
    this.sectionTitleStyle,
  });

  final WorkLinkNeighbors neighbors;
  final bool loading;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final TextStyle? characterTitleStyle;
  final TextStyle? sectionTitleStyle;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (neighbors.characters.isNotEmpty) ...[
          Text('주요 인물', style: sectionTitleStyle ?? _defaultSectionTitle),
          const SizedBox(height: 12),
          WorkLinkCharacterRow(
            characters: neighbors.characters,
            onOpenEntity: onOpenEntity,
          ),
          const SizedBox(height: 24),
        ],
        if (neighbors.connectedWorks.isNotEmpty) ...[
          Text('연결된 작품', style: sectionTitleStyle ?? _defaultSectionTitle),
          const SizedBox(height: 12),
          WorkLinkConnectedWorksList(
            works: neighbors.connectedWorks,
            onOpenWork: onOpenWork,
          ),
        ],
      ],
    );
  }

  static const _defaultSectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
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
