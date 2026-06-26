import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/browse_card.dart';
import '../../../models/collectible_browse_item.dart';
import '../../../models/collectible_collection.dart';
import '../../../models/entity_browse_card.dart';
import '../../../models/entity_gallery_sort.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/collectible_collection_pipeline.dart';
import '../../../services/entity_related_works_discovery.dart';
import '../../../widgets/entity_curated_reorder_grid.dart';
import 'catalog_entity_browse_loader.dart';
import 'catalog_entity_browse_widgets.dart';

export 'catalog_entity_browse_loader.dart' show CatalogEntityBrowseLoader;
export 'catalog_entity_browse_widgets.dart'
    show CatalogEntityBrowseCompactCard, CatalogEntityBrowseCompactStrip;

/// Tier 1.5 catalog Entity gallery — Wave 4 browse · R2-E Phase 1.
class CatalogEntityBrowseView extends StatefulWidget {
  const CatalogEntityBrowseView({
    super.key,
    required this.userCatalog,
    required this.scope,
    this.linkIndex,
    this.vaultItems = const [],
    this.onOpenWork,
    this.onOpenEntity,
    this.compact = false,
    this.highlightEntityId,
    this.entityGallerySort = EntityGallerySortCriteria.recentlyAdded,
    this.onEntityGallerySortChanged,
    this.collection,
    this.onCuratedReorder,
    this.onCollectibleCuratedReorder,
    this.relatedWorksDiscoveryFactory,
    this.posterCardBuilder,
    this.onAddNewEntity,
  });

  final UserCatalogPort userCatalog;
  final BrowseEntityScope scope;
  final RecordLinkPort? linkIndex;
  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item)? onOpenWork;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
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
  final Future<void> Function(
    List<CollectibleBrowseItem> visibleItems,
    int oldIndex,
    int newIndex,
  )? onCollectibleCuratedReorder;
  final EntityRelatedWorksDiscovery Function()? relatedWorksDiscoveryFactory;
  final Widget Function(BrowseCard card)? posterCardBuilder;
  final void Function(EntityAnchorType? type)? onAddNewEntity;

  @override
  State<CatalogEntityBrowseView> createState() =>
      _CatalogEntityBrowseViewState();
}

class _CatalogEntityBrowseViewState extends State<CatalogEntityBrowseView> {
  List<EntityBrowseCard> _cards = const [];
  List<CollectibleBrowseItem> _browseItems = const [];
  bool _loading = true;

  bool get _usesCollectibleBrowse => widget.collection != null;
  bool get _isMixedBrowse =>
      _browseItems.any((item) => item is WorkCollectibleBrowseItem);
  int get _itemCount =>
      _usesCollectibleBrowse ? _browseItems.length : _cards.length;

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
        !_usesCollectibleBrowse &&
        _cards.isNotEmpty) {
      setState(() {
        _cards = CatalogEntityBrowseLoader.applySort(
          _cards,
          widget.entityGallerySort,
        );
      });
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.userCatalog.load();
    if (!mounted) return;

    final relatedWorksDiscovery = widget.relatedWorksDiscoveryFactory?.call();
    final collection = widget.collection;

    if (collection != null) {
      final members = await CollectibleCollectionPipeline.resolveMembers(
        collection: collection,
        catalog: widget.userCatalog.all,
        vaultItems: widget.vaultItems,
        relatedWorksDiscovery: relatedWorksDiscovery,
      );
      var browseItems = await CatalogEntityBrowseLoader.buildCollectibleBrowseItems(
        members: members,
        linkIndex: widget.linkIndex,
        relatedWorksDiscovery: relatedWorksDiscovery,
      );
      if (!collection.isCurated) {
        browseItems = CatalogEntityBrowseLoader.sortCollectibleBrowseItems(
          browseItems,
          _effectiveSortCriteria(),
        );
      }
      if (!mounted) return;
      setState(() {
        _browseItems = browseItems;
        _cards = const [];
        _loading = false;
      });
      return;
    }

    final typeFilter = widget.scope.catalogEntityType;
    final all = widget.userCatalog.all.where((e) => !e.isWorkEntity);
    final filtered = typeFilter == null
        ? all.toList()
        : all.where((e) => e.anchorType == typeFilter).toList();

    final cards = await CatalogEntityBrowseLoader.buildBrowseCards(
      entities: filtered,
      linkIndex: widget.linkIndex,
      relatedWorksDiscovery: relatedWorksDiscovery,
    );
    if (!mounted) return;

    final sortCriteria = _effectiveSortCriteria();
    setState(() {
      _browseItems = const [];
      _cards = CatalogEntityBrowseLoader.applySort(cards, sortCriteria);
      _loading = false;
    });
  }

  EntityGallerySortCriteria _effectiveSortCriteria() {
    return CatalogEntityBrowseLoader.effectiveSortCriteria(
      requested: widget.entityGallerySort,
      collectionIsCurated: widget.collection?.isCurated == true,
    );
  }

  EntityGallerySortCriteria _effectiveSortCriteriaFor(
    EntityGallerySortCriteria criteria,
  ) {
    return CatalogEntityBrowseLoader.effectiveSortCriteria(
      requested: criteria,
      collectionIsCurated: widget.collection?.isCurated == true,
    );
  }

  void _openWork(BrowseCard card) {
    widget.onOpenWork?.call(card.item);
  }

  void _openEntity(UserCatalogEntity entity) {
    widget.onOpenEntity?.call(entity);
  }

  void _onSortChanged(EntityGallerySortCriteria criteria) {
    widget.onEntityGallerySortChanged?.call(criteria);
    setState(() {
      final effective = _effectiveSortCriteriaFor(criteria);
      if (_usesCollectibleBrowse) {
        _browseItems = CatalogEntityBrowseLoader.sortCollectibleBrowseItems(
          _browseItems,
          effective,
        );
      } else {
        _cards = CatalogEntityBrowseLoader.applySort(_cards, effective);
      }
    });
  }

  bool get _useCuratedReorder {
    if (widget.collection?.isCurated != true ||
        !widget.entityGallerySort.isManualOrder ||
        _itemCount <= 1) {
      return false;
    }
    if (_isMixedBrowse) {
      return widget.onCollectibleCuratedReorder != null &&
          widget.posterCardBuilder != null;
    }
    return widget.onCuratedReorder != null;
  }

  bool get _useMixedCuratedReorder =>
      _useCuratedReorder && _isMixedBrowse;

  String get _headerTitle {
    final collection = widget.collection;
    if (collection != null) {
      return '${collection.title} ($_itemCount)';
    }
    return '${widget.scope.label} 갤러리 ($_itemCount)';
  }

  List<EntityGallerySortCriteria> get _sortOptions {
    if (widget.collection?.isCurated == true) {
      return EntityGallerySortCriteria.curatedCollectionOptions;
    }
    return EntityGallerySortCriteria.galleryOptions;
  }

  List<EntityBrowseCard> get _entityCardsForDisplay {
    if (_usesCollectibleBrowse) {
      return _browseItems
          .whereType<EntityCollectibleBrowseItem>()
          .map((item) => item.card)
          .toList();
    }
    return _cards;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_itemCount == 0) {
      if (widget.compact) return const SizedBox.shrink();
      return CatalogEntityBrowseEmptyState(
        message: CatalogEntityBrowseEmptyState.messageFor(
          collection: widget.collection,
          scope: widget.scope,
        ),
        catalogEntityType: widget.scope.catalogEntityType,
        onAddNewEntity: widget.onAddNewEntity,
      );
    }

    if (widget.compact) {
      return CatalogEntityBrowseCompactStrip(
        cards: _cards,
        highlightEntityId: widget.highlightEntityId,
        onOpenEntity: _openEntity,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CatalogEntityBrowseHeader(
          title: _headerTitle,
          catalogEntityType: widget.scope.catalogEntityType,
          onAddNewEntity: widget.onAddNewEntity,
          sortCriteria: widget.onEntityGallerySortChanged != null
              ? widget.entityGallerySort
              : null,
          sortOptions: _sortOptions,
          onSortChanged: widget.onEntityGallerySortChanged != null
              ? _onSortChanged
              : null,
        ),
        Expanded(child: _buildGalleryBody()),
      ],
    );
  }

  Widget _buildGalleryBody() {
    if (_useMixedCuratedReorder) {
      return CollectibleCuratedReorderGrid(
        items: _browseItems,
        highlightEntityId: widget.highlightEntityId,
        posterCardBuilder: widget.posterCardBuilder!,
        onOpenWork: _openWork,
        onOpenEntity: (card) => _openEntity(card.entity),
        onReorder: (oldIndex, newIndex) async {
          await widget.onCollectibleCuratedReorder!(
            _browseItems,
            oldIndex,
            newIndex,
          );
          if (mounted) await _reload();
        },
      );
    }

    if (_useCuratedReorder) {
      return EntityCuratedReorderGrid(
        cards: _entityCardsForDisplay,
        highlightEntityId: widget.highlightEntityId,
        onOpenEntity: (card) => _openEntity(card.entity),
        onReorder: (oldIndex, newIndex) async {
          await widget.onCuratedReorder!(
            _entityCardsForDisplay,
            oldIndex,
            newIndex,
          );
          if (mounted) await _reload();
        },
      );
    }

    if (_usesCollectibleBrowse) {
      final posterBuilder = widget.posterCardBuilder;
      if (posterBuilder == null) {
        return CatalogEntityBrowseGalleryGrid(
          cards: _entityCardsForDisplay,
          highlightEntityId: widget.highlightEntityId,
          onOpenEntity: (card) => _openEntity(card.entity),
        );
      }
      return CatalogEntityBrowseMixedGalleryGrid(
        items: _browseItems,
        highlightEntityId: widget.highlightEntityId,
        posterCardBuilder: posterBuilder,
        onOpenWork: _openWork,
        onOpenEntity: (card) => _openEntity(card.entity),
        isMixedBrowse: _isMixedBrowse,
      );
    }

    return CatalogEntityBrowseGalleryGrid(
      cards: _cards,
      highlightEntityId: widget.highlightEntityId,
      onOpenEntity: (card) => _openEntity(card.entity),
    );
  }
}
