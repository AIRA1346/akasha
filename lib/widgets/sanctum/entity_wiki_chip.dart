import 'package:flutter/material.dart';

import '../../core/archiving/entity_anchor.dart';
import '../../core/archiving/record_link.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../theme/akasha_palette.dart';
import '../poster_image.dart';

/// Sanctum 미리보기 — wiki 링크 인라인 칩 (아바타 + 제목).
class EntityWikiChip extends StatelessWidget {
  const EntityWikiChip({
    super.key,
    required this.entityId,
    required this.title,
    this.userCatalog,
    this.onTap,
    this.compact = true,
  });

  final String entityId;
  final String title;
  final UserCatalogPort? userCatalog;
  final void Function(ParsedRecordLink link)? onTap;
  final bool compact;

  static ParsedRecordLink linkFromMatch(RegExpMatch match) {
    final primary = match.group(1)!.trim();
    final label = match.group(2)?.trim();
    return ParsedRecordLink(
      kind: RecordLinkKind.explicitId,
      raw: match.group(0)!,
      targetEntityId: primary,
      displayLabel: label != null && label.isNotEmpty ? label : primary,
    );
  }

  AkashaItem _avatarItem() {
    final entity = userCatalog?.getById(entityId);
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
      entityType: EntityAnchorType.object,
      entityId: entityId,
      title: title,
      category: MediaCategory.book,
      domain: AppDomain.subculture,
      addedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final avatarSize = compact ? 18.0 : 24.0;
    final fontSize = compact ? 12.0 : 13.0;
    final link = ParsedRecordLink(
      kind: RecordLinkKind.explicitId,
      raw: '[[$entityId|$title]]',
      targetEntityId: entityId,
      displayLabel: title,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(link),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: palette.workbenchTile,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: PosterImage(item: _avatarItem(), fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: compact ? 5 : 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
