import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../models/browse_card.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/collectible_browse_item.dart';
import '../../../models/collectible_collection.dart';
import '../../../models/entity_browse_card.dart';
import '../../../models/entity_gallery_sort.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_typography.dart';
import '../../../widgets/entity_collectible_card.dart';
import '../../../widgets/entity_gallery_sort_dropdown.dart';
import '../dialogs/add_catalog_entity_dialog.dart';

class CatalogEntityBrowseEmptyState extends StatelessWidget {
  const CatalogEntityBrowseEmptyState({
    super.key,
    required this.message,
    this.catalogEntityType,
    this.onAddNewEntity,
  });

  final String message;
  final EntityAnchorType? catalogEntityType;
  final void Function(EntityAnchorType? type)? onAddNewEntity;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AkashaColors.textCaption,
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AkashaColors.textMuted)),
          if (onAddNewEntity != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onAddNewEntity?.call(catalogEntityType),
              icon: const Icon(Icons.add),
              label: const Text('아카이브에 추가'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accentSoft,
                foregroundColor: palette.accent,
                side: BorderSide(color: palette.accent.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String messageFor({
    CollectibleCollection? collection,
    required BrowseEntityScope scope,
  }) {
    if (collection != null) {
      return collection.isCurated
          ? '컬렉션에 Work 또는 Entity를 추가해 보세요.'
          : '조건에 맞는 Entity가 없습니다.';
    }
    return switch (scope) {
      BrowseEntityScope.person => '아카이브된 Person이 없습니다.',
      BrowseEntityScope.concept => '아카이브된 Concept이 없습니다.',
      BrowseEntityScope.event => '아카이브된 Event가 없습니다.',
      BrowseEntityScope.place => '아카이브된 Place가 없습니다.',
      BrowseEntityScope.organization => '아카이브된 Organization이 없습니다.',
      _ => '아카이브된 Entity가 없습니다.',
    };
  }
}

class CatalogEntityBrowseCompactStrip extends StatelessWidget {
  const CatalogEntityBrowseCompactStrip({
    super.key,
    required this.cards,
    required this.highlightEntityId,
    required this.onOpenEntity,
  });

  final List<EntityBrowseCard> cards;
  final String? highlightEntityId;
  final void Function(UserCatalogEntity entity) onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return SizedBox(
      height: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Entity Discovery · ${cards.length}',
              style: AkashaTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = cards[index];
                return CatalogEntityBrowseCompactCard(
                  entity: card.entity,
                  highlighted: card.entity.entityId == highlightEntityId,
                  onTap: () => onOpenEntity(card.entity),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogEntityBrowseCompactCard extends StatelessWidget {
  const CatalogEntityBrowseCompactCard({
    super.key,
    required this.entity,
    required this.onTap,
    this.highlighted = false,
  });

  final UserCatalogEntity entity;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Material(
      color: highlighted ? palette.hoverSurface : palette.workbenchTile,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: palette.accent, width: 1.5),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entityTypeBadgeLabel(entity.anchorType),
                  style: AkashaTypography.caption.copyWith(
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AkashaTypography.listItemTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CatalogEntityBrowseHeader extends StatelessWidget {
  const CatalogEntityBrowseHeader({
    super.key,
    required this.title,
    this.catalogEntityType,
    this.onAddNewEntity,
    this.sortCriteria,
    this.sortOptions = const [],
    this.onSortChanged,
  });

  final String title;
  final EntityAnchorType? catalogEntityType;
  final void Function(EntityAnchorType? type)? onAddNewEntity;
  final EntityGallerySortCriteria? sortCriteria;
  final List<EntityGallerySortCriteria> sortOptions;
  final ValueChanged<EntityGallerySortCriteria>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: AkashaTypography.dashboardPanelTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onAddNewEntity != null) ...[
            TextButton.icon(
              onPressed: () => onAddNewEntity?.call(catalogEntityType),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가'),
              style: TextButton.styleFrom(foregroundColor: palette.accent),
            ),
            const SizedBox(width: 8),
          ],
          if (sortCriteria != null && onSortChanged != null)
            EntityGallerySortDropdown(
              currentCriteria: sortCriteria!,
              options: sortOptions,
              onChanged: onSortChanged!,
            ),
        ],
      ),
    );
  }
}

class CatalogEntityBrowseGalleryGrid extends StatelessWidget {
  const CatalogEntityBrowseGalleryGrid({
    super.key,
    required this.cards,
    required this.highlightEntityId,
    required this.onOpenEntity,
    this.cardMinWidth = 170,
    this.childAspectRatio = 0.68,
  });

  final List<EntityBrowseCard> cards;
  final String? highlightEntityId;
  final void Function(EntityBrowseCard card) onOpenEntity;
  final double cardMinWidth;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0) return const SizedBox.shrink();

        final crossAxisCount = (maxWidth / cardMinWidth).floor().clamp(2, 8);

        return Scrollbar(
          thumbVisibility: true,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return EntityCollectibleCard(
                card: card,
                highlighted: card.entity.entityId == highlightEntityId,
                onTap: () => onOpenEntity(card),
              );
            },
          ),
        );
      },
    );
  }
}

class CatalogEntityBrowseMixedGalleryGrid extends StatelessWidget {
  const CatalogEntityBrowseMixedGalleryGrid({
    super.key,
    required this.items,
    required this.highlightEntityId,
    required this.posterCardBuilder,
    required this.onOpenWork,
    required this.onOpenEntity,
    this.isMixedBrowse = false,
    this.cardMinWidth = 170,
    this.childAspectRatio = 0.68,
    this.mixedChildAspectRatio = 0.72,
  });

  final List<CollectibleBrowseItem> items;
  final String? highlightEntityId;
  final Widget Function(BrowseCard card) posterCardBuilder;
  final void Function(BrowseCard card) onOpenWork;
  final void Function(EntityBrowseCard card) onOpenEntity;
  final bool isMixedBrowse;
  final double cardMinWidth;
  final double childAspectRatio;
  final double mixedChildAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0) return const SizedBox.shrink();

        final crossAxisCount = (maxWidth / cardMinWidth).floor().clamp(2, 8);
        final aspectRatio = isMixedBrowse
            ? mixedChildAspectRatio
            : childAspectRatio;

        return Scrollbar(
          thumbVisibility: true,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return switch (item) {
                WorkCollectibleBrowseItem(:final card) => GestureDetector(
                  onTap: () => onOpenWork(card),
                  child: posterCardBuilder(card),
                ),
                EntityCollectibleBrowseItem(:final card) =>
                  EntityCollectibleCard(
                    card: card,
                    highlighted: card.entity.entityId == highlightEntityId,
                    onTap: () => onOpenEntity(card),
                  ),
              };
            },
          ),
        );
      },
    );
  }
}
