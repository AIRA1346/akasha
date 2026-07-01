part of 'home_dialogs_coordinator.dart';

Future<void> _homeDialogsCoordinatorOpenSearchDialog(
  HomeDialogsCoordinator coord,
) async {
  final ctx = coord.hostContext();
  await HomeDialogsFacade.showSearchDialog(
    context: ctx,
    localItems: coord.getItems(),
    userCatalog: coord.userCatalog,
    registry: coord.catalog.registry,
    onSelectLocal:
        coord.onPreviewLocalWork ?? coord.workbenchCoord.openBrowseItem,
    onSelectRemote: (work) async {
      if (!coord.isMounted()) return;
      final type = EntityIdCodec.typeFromId(work.workId);
      if (type != null && type != EntityAnchorType.work) {
        await _homeDialogsCoordinatorOpenEntityFromSearch(coord, work.workId);
        return;
      }
      final item = HomeAutoArchive.itemFromRegistryWork(work);
      if (coord.onPreviewLocalWork != null) {
        coord.onPreviewLocalWork!(item);
      } else {
        coord.workbenchCoord.openBrowseItem(item);
      }
    },
    onPromoteCatalogEntity: (work) =>
        _homeDialogsCoordinatorPromoteCatalogOnlyToArchive(coord, work),
    onCustomAdd: (query) async {
      if (!coord.vault.isVaultLinked) {
        coord.showMessage(
          lookupAppL10n(ctx)?.errorConnectVaultFirst ?? '볼트를 먼저 연결해 주세요.',
        );
        return;
      }
      await HomeDialogsFacade.showCustomAddWithTypePicker(
        context: ctx,
        query: query,
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
        onEntitySaved: (result) async {
          final vaultPath = coord.vault.vaultPath;
          if (vaultPath == null || vaultPath.isEmpty) {
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
        },
      );
    },
    onCatalogPropose: HomeDialogsFacade.catalogProposeCallback(
      context: ctx,
      refreshContributionCount: coord.catalog.syncCatalogContributionCount,
      showMessage: coord.showMessage,
    ),
    onAddLocalToLibrary: coord.canAddToLibrary()
        ? (item) => coord.wiring.libraryUi.showAddToLibraryForItem(
            ctx,
            item: item,
            isCuratedLibraryActive: coord.navigation.isCuratedLibraryActive,
            items: coord.getItems(),
            resolveItemForOpen: coord.workbenchCoord.resolveItemForOpen,
            setState: coord.wrapSetState,
            onCreateLibrary: () => coord.wiring.libraryUi
                .promptCreateCuratedLibrary(ctx, setState: coord.wrapSetState),
          )
        : null,
    onAddRemoteToLibrary: coord.canAddToLibrary()
        ? (work) => coord.wiring.libraryUi.addRegistryWorkToLibrary(
            ctx,
            work: work,
            isCuratedLibraryActive: coord.navigation.isCuratedLibraryActive,
            items: coord.getItems(),
            resolveItemForOpen: coord.workbenchCoord.resolveItemForOpen,
            setState: coord.wrapSetState,
            onCreateLibrary: () => coord.wiring.libraryUi
                .promptCreateCuratedLibrary(ctx, setState: coord.wrapSetState),
          )
        : null,
  );
}

Future<void> _homeDialogsCoordinatorOpenEntityFromSearch(
  HomeDialogsCoordinator coord,
  String entityId,
) async {
  final l10n = lookupAppL10n(coord.hostContext());
  final entity = await CollectibleOpener.findEntity(
    coord.userCatalog,
    entityId,
  );
  if (entity == null) {
    coord.showMessage(
      l10n != null
          ? l10n.errorEntityNotFound(entityId)
          : '「$entityId」을(를) 찾을 수 없습니다.',
    );
    return;
  }
  if (coord.onPreviewEntity != null) {
    coord.onPreviewEntity!(entity);
    return;
  }
  await coord.workbenchCoord.openEntity(entity);
}

Future<void> _homeDialogsCoordinatorPromoteCatalogOnlyToArchive(
  HomeDialogsCoordinator coord,
  RegistryWork work,
) async {
  final l10n = lookupAppL10n(coord.hostContext());
  final vaultPath = coord.vault.vaultPath;
  if (vaultPath == null || vaultPath.isEmpty) {
    final ctx = coord.hostContext();
    coord.showMessage(
      lookupAppL10n(ctx)?.errorConnectVaultFirst ?? '볼트를 먼저 연결해 주세요.',
    );
    return;
  }

  await coord.userCatalog.load();
  UserCatalogEntity? entity;
  for (final candidate in coord.userCatalog.all) {
    if (candidate.entityId == work.workId) {
      entity = candidate;
      break;
    }
  }
  if (entity == null) {
    coord.showMessage(
      l10n != null
          ? l10n.errorEntityNotFound(work.title)
          : '「${work.title}」을(를) 찾을 수 없습니다.',
    );
    return;
  }

  final existing = await const EntityVaultLoader().findByEntityId(
    vaultPath,
    entity.entityId,
  );
  if (existing != null) {
    await _homeDialogsCoordinatorOpenEntityFromSearch(coord, entity.entityId);
    return;
  }

  try {
    final entry = await EntityArchiveService.promoteCatalogOnly(
      entity: entity,
      vaultPath: vaultPath,
    );
    final mirrored = EntityCatalogSync.mirrorFromJournal(
      draft: entity,
      entry: entry,
    );
    await coord.userCatalog.upsert(mirrored);
    await coord.loadItems();
    if (!coord.isMounted()) return;

    await coord.workbenchCoord.openEntity(mirrored);
    coord.onEntityArchived?.call(mirrored, entry);
  } on EntityVaultPathConflict catch (e) {
    coord.showMessage(e.userMessage);
  }
}

Future<void> _homeDialogsCoordinatorOnAddWorksFromLibraryEdit(
  HomeDialogsCoordinator coord,
) async {
  await _homeDialogsCoordinatorOpenSearchDialog(coord);
  await coord.loadItems();
}
