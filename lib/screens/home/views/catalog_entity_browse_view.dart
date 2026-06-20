import 'package:flutter/material.dart';

import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/collectible_collection.dart';
import '../../../models/entity_browse_card.dart';
import '../../../models/entity_gallery_sort.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/collectible_collection_pipeline.dart';
import '../../../services/entity_related_works_discovery.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/file_service.dart';
import '../../../utils/entity_body_preview.dart';
import '../../../utils/entity_browse_sort.dart';
import '../../../widgets/entity_collectible_card.dart';
import '../../../widgets/entity_curated_reorder_grid.dart';
import '../../../widgets/entity_gallery_sort_dropdown.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../dialogs/entity_journal_dialog.dart';

/// Tier 1.5 catalog Entity gallery — Wave 4 browse · R2-E Phase 1.
class CatalogEntityBrowseView extends StatefulWidget {
  const CatalogEntityBrowseView({
    super.key,
    required this.userCatalog,
    required this.scope,
    this.linkIndex,
    this.vaultItems = const [],
    this.onOpenWork,
    this.compact = false,
    this.highlightEntityId,
    this.entityGallerySort = EntityGallerySortCriteria.recentlyAdded,
    this.onEntityGallerySortChanged,
    this.collection,
    this.onCuratedReorder,
    this.relatedWorksDiscoveryFactory,
  });

  final UserCatalogPort userCatalog;
  final BrowseEntityScope scope;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item)? onOpenWork;
  final bool compact;
  final String? highlightEntityId;
  final EntityGallerySortCriteria entityGallerySort;
  final ValueChanged<EntityGallerySortCriteria>? onEntityGallerySortChanged;
  final CollectibleCollection? collection;
  final Future<void> Function(
    List<EntityBrowseCard> visibleCards,
    int oldIndex,
    int newIndex,
  )? onCuratedReorder;
  final EntityRelatedWorksDiscovery Function()? relatedWorksDiscoveryFactory;

  @override
  State<CatalogEntityBrowseView> createState() =>
      _CatalogEntityBrowseViewState();
}

class _CatalogEntityBrowseViewState extends State<CatalogEntityBrowseView> {
  static const double _cardMinWidth = 170;
  static const double _childAspectRatio = 0.68;

  List<EntityBrowseCard> _cards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
    widget.userCatalog.onChanged.listen((_) {
      if (mounted) _reload();
    });
  }

  @override
  void didUpdateWidget(covariant CatalogEntityBrowseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope ||
        oldWidget.collection?.id != widget.collection?.id) {
      _reload();
      return;
    }
    if (oldWidget.entityGallerySort != widget.entityGallerySort &&
        !_loading &&
        _cards.isNotEmpty) {
      setState(() {
        _cards = sortEntityBrowseCards(_cards, widget.entityGallerySort);
      });
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.userCatalog.load();
    if (!mounted) return;

    List<UserCatalogEntity> filtered;
    final collection = widget.collection;
    if (collection != null) {
      filtered = await CollectibleCollectionPipeline.resolve(
        collection: collection,
        catalog: widget.userCatalog.all,
        relatedWorksDiscovery: widget.relatedWorksDiscoveryFactory?.call(),
      );
    } else {
      final typeFilter = widget.scope.catalogEntityType;
      final all = widget.userCatalog.all.where((e) => !e.isWorkEntity);
      filtered = typeFilter == null
          ? all.toList()
          : all.where((e) => e.anchorType == typeFilter).toList();
    }

    final cards = await _buildBrowseCards(filtered);
    if (!mounted) return;

    final sortCriteria = _effectiveSortCriteria();
    setState(() {
      _cards = _applySort(cards, sortCriteria);
      _loading = false;
    });
  }

  EntityGallerySortCriteria _effectiveSortCriteria() {
    if (widget.collection?.isCurated == true &&
        widget.entityGallerySort.isManualOrder) {
      return EntityGallerySortCriteria.manualOrder;
    }
    return widget.entityGallerySort;
  }

  List<EntityBrowseCard> _applySort(
    List<EntityBrowseCard> cards,
    EntityGallerySortCriteria criteria,
  ) {
    if (criteria.isManualOrder) return cards;
    return sortEntityBrowseCards(cards, criteria);
  }

  Future<List<EntityBrowseCard>> _buildBrowseCards(
    List<UserCatalogEntity> entities,
  ) async {
    final vaultPath = AkashaFileService().vaultPath;
    final journals = await const EntityVaultLoader().loadFromVault(vaultPath);
    final byId = {for (final j in journals) j.entityId: j};

    final cards = <EntityBrowseCard>[];
    final linkIndex = widget.linkIndex;
    List<List<String>> incomingByEntity = const [];
    if (linkIndex != null && entities.isNotEmpty) {
      incomingByEntity = await Future.wait(
        entities.map((e) => linkIndex.incomingRecordPaths(e.entityId)),
      );
    }

    for (var i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final journal = byId[entity.entityId];
      final incoming = linkIndex != null ? incomingByEntity[i].length : 0;
      final body = journal?.body.trim() ?? '';
      cards.add(
        EntityBrowseCard(
          entity: entity,
          journal: journal,
          isArchived: journal != null,
          incomingRecordCount: incoming,
          bodyPreview: body.isEmpty ? '' : EntityBodyPreview.format(body),
        ),
      );
    }
    return cards;
  }

  Future<void> _openEntity(UserCatalogEntity entity) async {
    final vaultPath = AkashaFileService().vaultPath;
    final entry = await const EntityVaultLoader().findByEntityId(
      vaultPath,
      entity.entityId,
    );
    if (!mounted) return;
    await showEntityJournalDialog(
      context,
      entity: entity,
      entry: entry,
      linkIndex: widget.linkIndex,
      userCatalog: widget.userCatalog,
      vaultItems: widget.vaultItems,
      onOpenWork: widget.onOpenWork,
    );
    if (mounted) await _reload();
  }

  void _onSortChanged(EntityGallerySortCriteria criteria) {
    widget.onEntityGallerySortChanged?.call(criteria);
    setState(() {
      _cards = _applySort(_cards, _effectiveSortCriteriaFor(criteria));
    });
  }

  EntityGallerySortCriteria _effectiveSortCriteriaFor(
    EntityGallerySortCriteria criteria,
  ) {
    if (widget.collection?.isCurated == true && criteria.isManualOrder) {
      return EntityGallerySortCriteria.manualOrder;
    }
    return criteria;
  }

  bool get _useCuratedReorder =>
      widget.collection?.isCurated == true &&
      widget.entityGallerySort.isManualOrder &&
      widget.onCuratedReorder != null &&
      _cards.length > 1;

  String get _headerTitle {
    final collection = widget.collection;
    if (collection != null) {
      return '${collection.title} (${_cards.length})';
    }
    return '${widget.scope.label} 갤러리 (${_cards.length})';
  }

  List<EntityGallerySortCriteria> get _sortOptions {
    if (widget.collection?.isCurated == true) {
      return EntityGallerySortCriteria.curatedCollectionOptions;
    }
    return EntityGallerySortCriteria.galleryOptions;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_entriesEmpty) {
      if (widget.compact) return const SizedBox.shrink();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              _emptyMessage,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (widget.compact) {
      return SizedBox(
        height: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                'Entity Discovery · ${_cards.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.tealAccent,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cards.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return _CompactEntityCard(
                    entity: card.entity,
                    highlighted:
                        card.entity.entityId == widget.highlightEntityId,
                    onTap: () => _openEntity(card.entity),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                _headerTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.onEntityGallerySortChanged != null)
                EntityGallerySortDropdown(
                  currentCriteria: widget.entityGallerySort,
                  options: _sortOptions,
                  onChanged: _onSortChanged,
                ),
            ],
          ),
        ),
        Expanded(
          child: _useCuratedReorder
              ? EntityCuratedReorderGrid(
                  cards: _cards,
                  highlightEntityId: widget.highlightEntityId,
                  onOpenEntity: (card) => _openEntity(card.entity),
                  onReorder: (oldIndex, newIndex) async {
                    await widget.onCuratedReorder!(
                      _cards,
                      oldIndex,
                      newIndex,
                    );
                    if (mounted) await _reload();
                  },
                )
              : _buildGalleryGrid(),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0) return const SizedBox.shrink();

        final crossAxisCount = (maxWidth / _cardMinWidth).floor().clamp(2, 8);

        return Scrollbar(
          thumbVisibility: true,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: _childAspectRatio,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              return EntityCollectibleCard(
                card: card,
                highlighted: card.entity.entityId == widget.highlightEntityId,
                onTap: () => _openEntity(card.entity),
              );
            },
          ),
        );
      },
    );
  }

  bool get _entriesEmpty => _cards.isEmpty;

  String get _emptyMessage {
    if (widget.collection != null) {
      return widget.collection!.isCurated
          ? '컬렉션에 Entity를 추가해 보세요.'
          : '조건에 맞는 Entity가 없습니다.';
    }
    return switch (widget.scope) {
      BrowseEntityScope.person => '아카이브된 Person이 없습니다.',
      BrowseEntityScope.concept => '아카이브된 Concept이 없습니다.',
      BrowseEntityScope.event => '아카이브된 Event가 없습니다.',
      BrowseEntityScope.place => '아카이브된 Place가 없습니다.',
      BrowseEntityScope.organization => '아카이브된 Organization이 없습니다.',
      _ => '아카이브된 Entity가 없습니다.',
    };
  }
}

class _CompactEntityCard extends StatelessWidget {
  const _CompactEntityCard({
    required this.entity,
    required this.onTap,
    this.highlighted = false,
  });

  final UserCatalogEntity entity;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF2A3540) : const Color(0xFF252535),
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.tealAccent, width: 1.5),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
