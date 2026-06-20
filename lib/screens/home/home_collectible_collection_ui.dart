import 'package:flutter/material.dart';

import '../../core/ports/user_catalog_port.dart';
import '../../models/collectible_collection.dart';
import '../../models/user_catalog_entity.dart';
import 'dialogs/collectible_collection_edit_dialog.dart';
import 'home_collectible_collection_controller.dart';
import 'home_personal_library_controller.dart';

/// Entity 컬렉션 편집·삭제 Presentation glue.
class HomeCollectibleCollectionUi {
  const HomeCollectibleCollectionUi({
    required this.collectionCtrl,
    this.userCatalog,
  });

  final HomeCollectibleCollectionController collectionCtrl;
  final UserCatalogPort? userCatalog;

  Future<List<UserCatalogEntity>> _loadCatalogEntities() async {
    final catalog = userCatalog;
    if (catalog == null) return const [];
    await catalog.load();
    return catalog.all.toList();
  }

  Future<void> promptCreate(
    BuildContext context, {
    required HomePersonalLibraryController personalLibCtrl,
    required void Function(void Function()) setState,
  }) async {
    final entities = await _loadCatalogEntities();
    if (!context.mounted) return;
    final created = await showCollectibleCollectionEditDialog(
      context,
      catalogEntities: entities,
    );
    if (created == null || !context.mounted) return;
    setState(() {
      collectionCtrl.add(created, personalLibCtrl: personalLibCtrl);
    });
    await collectionCtrl.save();
  }

  Future<void> showEditDialog(
    BuildContext context, {
    required CollectibleCollection config,
    required void Function(void Function()) setState,
  }) async {
    final entities = await _loadCatalogEntities();
    if (!context.mounted) return;
    final updated = await showCollectibleCollectionEditDialog(
      context,
      config: config,
      catalogEntities: entities,
    );
    if (updated == null || !context.mounted) return;
    setState(() {});
    await collectionCtrl.save();
  }

  Future<void> confirmDelete(
    BuildContext context, {
    required String id,
    required void Function(void Function()) setState,
  }) async {
    final confirmed = await showDeleteCollectibleCollectionConfirmDialog(
      context,
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => collectionCtrl.remove(id));
    await collectionCtrl.save();
    await collectionCtrl.saveActiveState();
  }
}
