import 'package:flutter/material.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../models/akasha_item.dart';
import '../models/registry_work.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../services/franchise_fusion_service.dart';
import '../services/franchise_registry.dart';
import '../services/registry_visibility_service.dart';
import '../theme/akasha_colors.dart';
import '../widgets/star_rating.dart';
import 'fusion_remote_search_entry.dart';

class FusionSearchSectionLabel extends StatelessWidget {
  const FusionSearchSectionLabel(this.title, this.count, {super.key});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent,
        ),
      ),
    );
  }
}

class FusionSearchLocalWorkTile extends StatelessWidget {
  const FusionSearchLocalWorkTile({
    super.key,
    required this.item,
    required this.onSelect,
    this.onAddToLibrary,
  });

  final AkashaItem item;
  final VoidCallback onSelect;
  final Future<void> Function()? onAddToLibrary;

  @override
  Widget build(BuildContext context) {
    final franchise = FranchiseRegistry.groupFor(item.workId);
    final formatLabels = franchise != null
        ? FranchiseFusionService.franchiseFormatLabels(franchise)
        : null;

    final subtitle = [
      item.creator.isNotEmpty ? item.creator : '내 아카이브',
      if (formatLabels != null && formatLabels.isNotEmpty) formatLabels,
    ].join(' · ');

    return ListTile(
      dense: true,
      leading: Icon(item.category.icon, size: 20),
      title: Text(
        franchise?.displayName ?? item.title,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onAddToLibrary != null)
            IconButton(
              icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
              tooltip: '서재에 담기',
              visualDensity: VisualDensity.compact,
              onPressed: onAddToLibrary,
            ),
          StarRating(rating: item.rating, size: 11),
        ],
      ),
      onTap: onSelect,
    );
  }
}

class FusionSearchLocalEntityTile extends StatelessWidget {
  const FusionSearchLocalEntityTile({
    super.key,
    required this.entry,
    required this.onSelect,
  });

  final EntityJournalEntry entry;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final badge = entityTypeBadgeLabel(entry.entityType);
    return ListTile(
      dense: true,
      leading: Icon(FusionSearchEntityIcons.forType(entry.entityType), size: 20),
      title: Text(entry.title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        '$badge · 내 아카이브',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badge,
          style: const TextStyle(fontSize: 10, color: Colors.tealAccent),
        ),
      ),
      onTap: onSelect,
    );
  }
}

class FusionSearchRemoteTile extends StatelessWidget {
  const FusionSearchRemoteTile({
    super.key,
    required this.entry,
    required this.onSelectRemote,
    required this.onRemoteTap,
    this.onAddRemoteToLibrary,
    this.onPromoteCatalogEntity,
  });

  final FusionRemoteSearchEntry entry;
  final Future<void> Function(RegistryWork work) onSelectRemote;
  final Future<void> Function(FusionRemoteSearchEntry entry) onRemoteTap;
  final Future<void> Function(RegistryWork work)? onAddRemoteToLibrary;
  final Future<void> Function(RegistryWork work)? onPromoteCatalogEntity;

  @override
  Widget build(BuildContext context) {
    final work = entry.work;
    final hint = entry.hint;
    final isUserLocal = entry.isUserLocal;
    final catalogOnly = entry.catalogOnly;
    final dimmed = !isUserLocal && hint != RegistryRemoteHint.available;
    final franchise = FranchiseRegistry.groupFor(work.workId);

    String? hintText;
    switch (hint) {
      case RegistryRemoteHint.siblingTracked:
        hintText = '다른 매체 버전 추적 중';
      case RegistryRemoteHint.hidden:
        hintText = '숨김됨';
      case RegistryRemoteHint.available:
        if (catalogOnly) hintText = '아카이브되지 않음';
    }

    final formatLabels =
        franchise != null ? FranchiseFusionService.franchiseFormatLabels(franchise) : null;

    final typeBadge = entry.entityType != EntityAnchorType.work
        ? entityTypeBadgeLabel(entry.entityType)
        : null;

    final subtitle = [
      work.creator.isNotEmpty
          ? work.creator
          : (isUserLocal ? '내 등록' : '글로벌 사전'),
      if (typeBadge != null)
        typeBadge
      else if (formatLabels != null && formatLabels.isNotEmpty)
        formatLabels
      else
        work.category.label,
      ?hintText,
    ].whereType<String>().join(' · ');

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: ListTile(
        dense: true,
        leading: Icon(
          catalogOnly
              ? FusionSearchEntityIcons.forType(entry.entityType)
              : work.category.icon,
          size: 20,
          color: dimmed ? AkashaColors.textMuted : Colors.lightBlueAccent,
        ),
        title: Text(
          franchise?.displayName ?? work.title,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: catalogOnly
                ? Colors.orange[300]
                : hint == RegistryRemoteHint.siblingTracked
                    ? Colors.orange[300]
                    : hint == RegistryRemoteHint.hidden
                        ? AkashaColors.textMuted
                        : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (catalogOnly && onPromoteCatalogEntity != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await onPromoteCatalogEntity!(work);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('아카이브하기', style: TextStyle(fontSize: 11)),
              )
            else if (onAddRemoteToLibrary != null &&
                (isUserLocal || hint == RegistryRemoteHint.available))
              TextButton(
                onPressed: () => onAddRemoteToLibrary!(work),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('담기', style: TextStyle(fontSize: 11)),
              ),
            if (!catalogOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isUserLocal ? Colors.teal : Colors.blue)
                      .withValues(alpha: dimmed ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUserLocal
                      ? (typeBadge ?? '내 아카이브')
                      : (hint == RegistryRemoteHint.available ? '사전' : '주의'),
                  style: TextStyle(
                    fontSize: 10,
                    color: dimmed && !isUserLocal
                        ? AkashaColors.textMuted
                        : (isUserLocal ? Colors.tealAccent : Colors.lightBlueAccent),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          if (isUserLocal && !catalogOnly) {
            Navigator.pop(context);
            onSelectRemote(work);
            return;
          }
          onRemoteTap(entry);
        },
      ),
    );
  }
}

/// Fusion search · entity link picker 공유 Entity 타입 아이콘.
abstract final class FusionSearchEntityIcons {
  static IconData forType(EntityAnchorType type) {
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
