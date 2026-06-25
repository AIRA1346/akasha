import 'package:flutter/material.dart';

import '../../core/archiving/entity_anchor.dart';
import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../models/sanctum_cast_entry.dart';
import '../../models/user_catalog_entity.dart';
import '../../theme/akasha_colors.dart';
import '../poster_image.dart';

/// Sanctum 미리보기 상단 — 출연 인물 가로 카드 스트립.
class SanctumCastStrip extends StatelessWidget {
  const SanctumCastStrip({
    super.key,
    required this.cast,
    this.userCatalog,
    this.onWikiLinkTap,
    this.onOpenEntity,
  });

  final List<SanctumCastEntry> cast;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  AkashaItem _avatarItem(SanctumCastEntry entry) {
    final entity = userCatalog?.getById(entry.entityId);
    if (entity != null) {
      return EntityItem(
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
    }

    return EntityItem(
      entityType: EntityAnchorType.person,
      entityId: entry.entityId,
      title: entry.title,
      category: MediaCategory.book,
      domain: AppDomain.subculture,
      addedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '출연',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cast.map((entry) {
                final catalogEntity = userCatalog?.getById(entry.entityId);
                final link = ParsedRecordLink(
                  kind: RecordLinkKind.explicitId,
                  raw: entry.wikiToken,
                  targetEntityId: entry.entityId,
                  displayLabel: entry.title,
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      if (catalogEntity != null && onOpenEntity != null) {
                        onOpenEntity!(catalogEntity);
                        return;
                      }
                      onWikiLinkTap?.call(link);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      child: Column(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: PosterImage(
                                item: _avatarItem(entry),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (entry.role != null && entry.role!.isNotEmpty)
                            Text(
                              entry.role!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AkashaColors.borderSubtle(0.08), height: 1),
        ],
      ),
    );
  }
}
