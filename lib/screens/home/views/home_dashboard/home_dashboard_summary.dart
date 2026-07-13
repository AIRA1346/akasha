import 'package:flutter/foundation.dart';

import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';

/// Actual, synchronously available archive facts shown by the Home Hero.
///
/// Connection totals are intentionally absent until the async link index has a
/// dedicated summary contract. The Hero must never manufacture a decorative
/// count while that source is unavailable.
@immutable
class HomeDashboardSummary {
  const HomeDashboardSummary({
    required this.archiveRecordCount,
    required this.entityCount,
    required this.collectionCount,
    required this.tagCount,
  });

  factory HomeDashboardSummary.fromArchive({
    required Iterable<AkashaItem> vaultItems,
    required Iterable<UserCatalogEntity> catalogEntities,
    required int collectionCount,
  }) {
    final items = vaultItems.toList(growable: false);
    final entities = catalogEntities.toList(growable: false);
    final normalizedTags = <String>{};

    for (final item in items) {
      _addTags(normalizedTags, item.tags);
    }
    for (final entity in entities) {
      _addTags(normalizedTags, entity.tags);
    }

    return HomeDashboardSummary(
      archiveRecordCount: items.length,
      entityCount: entities.where((entity) => !entity.isWorkEntity).length,
      collectionCount: collectionCount,
      tagCount: normalizedTags.length,
    );
  }

  final int archiveRecordCount;
  final int entityCount;
  final int collectionCount;
  final int tagCount;

  bool get isEmpty =>
      archiveRecordCount == 0 &&
      entityCount == 0 &&
      collectionCount == 0 &&
      tagCount == 0;

  static void _addTags(Set<String> target, Iterable<String> tags) {
    for (final tag in tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isNotEmpty) target.add(normalized);
    }
  }
}
