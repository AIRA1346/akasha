part of 'home_dialogs_coordinator.dart';

Future<void> _homeDialogsCoordinatorOpenAddEntityDialog(
  HomeDialogsCoordinator coord,
  EntityAnchorType? forceType,
) async {
  final ctx = coord.hostContext();
  final vaultPath = coord.vault.vaultPath;
  if (vaultPath == null || vaultPath.isEmpty) {
    coord.showMessage(
      lookupAppL10n(ctx)?.errorConnectVaultFirst ?? '볼트를 먼저 연결해 주세요.',
    );
    return;
  }

  if (forceType == null) {
    await HomeDialogsFacade.showCustomAddWithTypePicker(
      context: ctx,
      query: '',
      isVaultLinked: coord.vault.isVaultLinked,
      vault: coord.vault.vault,
      showMessage: coord.showMessage,
      userCatalog: coord.userCatalog,
      vaultItems: coord.getItems(),
      onWorkSavedToVault: (item) async {
        await coord.vault.saveVaultItem(item);
        if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
          await coord.userCatalog.upsert(
            UserCatalogEntity.fromAkashaItem(item),
          );
        }
        await coord.loadItems();
      },
      onEntitySaved: (result) =>
          _homeDialogsCoordinatorSaveEntityResult(coord, result),
    );
    return;
  }

  if (forceType == EntityAnchorType.work) {
    await HomeDialogsFacade.showAddDialog(
      context: ctx,
      initialTitle: '',
      isVaultLinked: coord.vault.isVaultLinked,
      vault: coord.vault.vault,
      showMessage: coord.showMessage,
      onSavedToVault: (item) async {
        await coord.vault.saveVaultItem(item);
        if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
          await coord.userCatalog.upsert(
            UserCatalogEntity.fromAkashaItem(item),
          );
        }
        await coord.loadItems();
      },
    );
    return;
  }

  await coord.userCatalog.load();
  if (!ctx.mounted) return;
  final workTitleIndex = EntityTagValidation.buildWorkTitleIndex(
    catalogEntities: coord.userCatalog.all,
    vaultItems: coord.getItems(),
  );

  final addResult = await showAddCatalogEntityDialog(
    ctx,
    entityType: forceType,
    initialTitle: '',
    workTitleIndex: workTitleIndex,
  );
  if (addResult == null || !coord.isMounted()) return;
  await _homeDialogsCoordinatorSaveEntityResult(coord, addResult);
}

Future<void> _homeDialogsCoordinatorSaveEntityResult(
  HomeDialogsCoordinator coord,
  CatalogEntityAddResult result,
) async {
  final vaultPath = coord.vault.vaultPath;
  if (vaultPath == null || vaultPath.isEmpty) {
    final ctx = coord.hostContext();
    coord.showMessage(
      lookupAppL10n(ctx)?.errorConnectVaultFirst ?? '볼트를 먼저 연결해 주세요.',
    );
    return;
  }
  try {
    final saved = await EntityArchiveService.saveFromAddResult(
      result: result,
      vaultPath: vaultPath,
      userCatalog: coord.userCatalog,
    );
    await coord.loadItems();
    if (!coord.isMounted()) return;

    if (saved.entry != null) {
      await coord.workbenchCoord.openEntity(saved.entity);
    }

    coord.onEntityArchived?.call(saved.entity, saved.entry);
  } on EntityVaultPathConflict catch (e) {
    coord.showMessage(e.userMessage);
  }
}
