import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import 'entity_tag_validator.dart';

/// Shared soft-warning for semantic tags that mirror work titles.
abstract final class EntityTagValidation {
  static Set<String> buildWorkTitleIndex({
    required Iterable<UserCatalogEntity> catalogEntities,
    Iterable<AkashaItem> vaultItems = const [],
  }) {
    return EntityTagValidator.buildWorkTitleIndex(
      catalogEntities: catalogEntities,
      vaultItems: vaultItems,
    );
  }

  static void showWorkTitleWarningIfNeeded(
    BuildContext context, {
    required List<String> tags,
    required Set<String> workTitles,
  }) {
    final offending = EntityTagValidator.findWorkTitleTags(tags, workTitles);
    if (offending.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(EntityTagValidator.warningMessage(offending)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
