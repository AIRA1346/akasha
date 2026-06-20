import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/collectible_kind.dart';
import '../models/collectible_ref.dart';
import '../models/user_catalog_entity.dart';

/// Phase 6 — Collectible tap dispatch (Workbench vs legacy Sheet fallback).
abstract final class CollectibleOpener {
  static Future<void> openRef({
    required CollectibleRef ref,
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
    required void Function(AkashaItem item) onOpenWork,
    required Future<void> Function(UserCatalogEntity entity) onOpenEntity,
  }) async {
    if (ref.kind == CollectibleKind.work) {
      for (final item in vaultItems) {
        if (item.workId == ref.id) {
          onOpenWork(item);
          return;
        }
      }
      return;
    }

    final entity = await _findEntity(userCatalog, ref.id);
    if (entity != null) {
      await onOpenEntity(entity);
    }
  }

  static Future<void> openEntityId({
    required String entityId,
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
    required void Function(AkashaItem item) onOpenWork,
    required Future<void> Function(UserCatalogEntity entity) onOpenEntity,
  }) async {
    if (entityId.startsWith('wk_') ||
        entityId.startsWith('sub_') ||
        entityId.startsWith('gen_')) {
      for (final item in vaultItems) {
        if (item.workId == entityId) {
          onOpenWork(item);
          return;
        }
      }
      return;
    }

    final entity = await _findEntity(userCatalog, entityId);
    if (entity != null) {
      await onOpenEntity(entity);
    }
  }

  static Future<UserCatalogEntity?> findEntity(
    UserCatalogPort userCatalog,
    String entityId,
  ) =>
      _findEntity(userCatalog, entityId);

  static Future<UserCatalogEntity?> _findEntity(
    UserCatalogPort userCatalog,
    String entityId,
  ) async {
    await userCatalog.load();
    for (final entity in userCatalog.all) {
      if (entity.entityId == entityId) return entity;
    }
    return null;
  }
}
