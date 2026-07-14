import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_typography.dart';
import 'poster_image.dart';

const workLinkCharacterGridPageSize = 6;

class WorkLinkCharacterPagedGrid extends StatefulWidget {
  const WorkLinkCharacterPagedGrid({
    super.key,
    required this.characters,
    this.onOpenEntity,
    this.pageSize = workLinkCharacterGridPageSize,
    this.columns = 3,
    this.imageSize = 58,
  }) : assert(pageSize > 0),
       assert(columns > 0);

  final List<UserCatalogEntity> characters;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final int pageSize;
  final int columns;
  final double imageSize;

  @override
  State<WorkLinkCharacterPagedGrid> createState() =>
      _WorkLinkCharacterPagedGridState();
}

class _WorkLinkCharacterPagedGridState
    extends State<WorkLinkCharacterPagedGrid> {
  int _page = 0;

  int get _pageCount {
    if (widget.characters.isEmpty) return 1;
    return ((widget.characters.length - 1) ~/ widget.pageSize) + 1;
  }

  @override
  void didUpdateWidget(covariant WorkLinkCharacterPagedGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lastPage = _pageCount - 1;
    if (_page > lastPage) _page = lastPage;
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _pageCount;
    final start = _page * widget.pageSize;
    final visibleCharacters = widget.characters
        .skip(start)
        .take(widget.pageSize)
        .toList();
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pageCount > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_page + 1} / $pageCount',
                style: AkashaTypography.micro.copyWith(
                  color: context.akashaPalette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              _CharacterPagerButton(
                icon: Icons.chevron_left_rounded,
                tooltip: localizations.previousPageTooltip,
                onPressed: _page == 0 ? null : () => setState(() => _page -= 1),
              ),
              const SizedBox(width: 4),
              _CharacterPagerButton(
                icon: Icons.chevron_right_rounded,
                tooltip: localizations.nextPageTooltip,
                onPressed: _page >= pageCount - 1
                    ? null
                    : () => setState(() => _page += 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCharacters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            return _CharacterGridTile(
              person: visibleCharacters[index],
              imageSize: widget.imageSize,
              onOpenEntity: widget.onOpenEntity,
            );
          },
        ),
      ],
    );
  }
}

class _CharacterPagerButton extends StatelessWidget {
  const _CharacterPagerButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? palette.workbenchTile : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.borderSubtle(0.22)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? palette.accent
                  : palette.textMuted.withValues(alpha: 0.56),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterGridTile extends StatelessWidget {
  const _CharacterGridTile({
    required this.person,
    required this.imageSize,
    this.onOpenEntity,
  });

  final UserCatalogEntity person;
  final double imageSize;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final imageWidth = imageSize * 1.08;
    final imageHeight = imageSize * 1.22;
    final hasPoster = person.posterPath?.trim().isNotEmpty ?? false;
    final avatar = hasPoster
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 112,
              height: 132,
              child: PosterImage(
                item: EntityItem(
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
                ),
                fit: BoxFit.cover,
              ),
            ),
          )
        : const _CharacterAvatarFallback();

    return Material(
      color: palette.workbenchTile,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpenEntity == null ? null : () => onOpenEntity!(person),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: avatar,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                person.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterAvatarFallback extends StatelessWidget {
  const _CharacterAvatarFallback();

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderSubtle(0.24)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: palette.accent.withValues(alpha: 0.92),
        size: 28,
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
    final palette = context.akashaPalette;
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
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

/// 워크벤치 우측 패널 — 인물 행 (mock 리스트형).
class WorkLinkCharacterWorkbenchList extends StatelessWidget {
  const WorkLinkCharacterWorkbenchList({
    super.key,
    required this.characters,
    this.onOpenEntity,
  });

  final List<UserCatalogEntity> characters;
  final void Function(UserCatalogEntity entity)? onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Column(
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
        final role = person.tags.isNotEmpty ? person.tags.first : '인물';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: palette.workbenchTile,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onOpenEntity == null ? null : () => onOpenEntity!(person),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(role, style: AkashaTypography.caption),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: palette.accent.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
