import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/file_service.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../dialogs/entity_journal_dialog.dart';

/// Tier 1.5 catalog Entity 목록 — Wave 4 browse filter.
class CatalogEntityBrowseView extends StatefulWidget {
  const CatalogEntityBrowseView({
    super.key,
    required this.userCatalog,
    required this.scope,
    this.compact = false,
  });

  final UserCatalogPort userCatalog;
  final BrowseEntityScope scope;
  final bool compact;

  @override
  State<CatalogEntityBrowseView> createState() =>
      _CatalogEntityBrowseViewState();
}

class _CatalogEntityBrowseViewState extends State<CatalogEntityBrowseView> {
  List<UserCatalogEntity> _entities = const [];
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
    if (oldWidget.scope != widget.scope) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.userCatalog.load();
    if (!mounted) return;

    final typeFilter = widget.scope.catalogEntityType;
    final all = widget.userCatalog.all.where((e) => !e.isWorkEntity);
    final filtered = typeFilter == null
        ? all.toList()
        : all.where((e) => e.anchorType == typeFilter).toList();

    filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    setState(() {
      _entities = filtered;
      _loading = false;
    });
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
    );
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
                '내 catalog Entity (${_entities.length})',
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
                itemCount: _entities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entity = _entities[index];
                  return _CompactEntityCard(
                    entity: entity,
                    onTap: () => _openEntity(entity),
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
          child: Text(
            '${widget.scope.label} catalog (${_entities.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _entities.length,
            separatorBuilder:  (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entity = _entities[index];
              return Material(
                color: const Color(0xFF252535),
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  leading: Icon(_iconFor(entity.anchorType)),
                  title: Text(entity.title),
                  subtitle: Text(
                    '${entityTypeBadgeLabel(entity.anchorType)} · ${entity.entityId}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => _openEntity(entity),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _entriesEmpty => _entities.isEmpty;

  String get _emptyMessage {
    return switch (widget.scope) {
      BrowseEntityScope.person => 'catalog에 Person이 없습니다.',
      BrowseEntityScope.concept => 'catalog에 Concept이 없습니다.',
      BrowseEntityScope.event => 'catalog에 Event가 없습니다.',
      _ => 'catalog에 Entity가 없습니다.',
    };
  }

  static IconData _iconFor(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => Icons.person_outline,
      EntityAnchorType.concept => Icons.lightbulb_outline,
      EntityAnchorType.event => Icons.event_outlined,
      EntityAnchorType.place => Icons.place_outlined,
      EntityAnchorType.organization => Icons.groups_outlined,
      _ => Icons.category_outlined,
    };
  }
}

class _CompactEntityCard extends StatelessWidget {
  const _CompactEntityCard({
    required this.entity,
    required this.onTap,
  });

  final UserCatalogEntity entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF252535),
      borderRadius: BorderRadius.circular(8),
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
