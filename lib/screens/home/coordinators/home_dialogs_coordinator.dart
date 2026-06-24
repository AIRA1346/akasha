import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_id_codec.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/work_id_codec.dart';
import '../../../models/library_theme.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_catalog_sync.dart';
import '../../../services/file_service.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/open_collectible.dart';
import '../dialogs/home_dialogs_facade.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../../../utils/entity_tag_validation.dart';
import '../home_auto_archive.dart';
import 'home_catalog_coordinator.dart';
import 'home_navigation_coordinator.dart';
import 'home_shell_wiring.dart';
import 'home_vault_coordinator.dart';
import 'home_workbench_coordinator.dart';

/// Home 다이얼로그·볼트 폴더 선택 (E2-4).
class HomeDialogsCoordinator {
  HomeDialogsCoordinator({
    required this.hostContext,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.showMessage,
    required this.wiring,
    required this.vault,
    required this.catalog,
    required this.navigation,
    required this.workbenchCoord,
    required this.getItems,
    required this.addItemInMemory,
    required this.loadItems,
    required this.loadPersonalLibraries,
    required this.autoArchiveWorks,
    required this.rebuild,
    required this.wrapSetState,
    required this.canAddToLibrary,
    required this.userCatalog,
    this.onEntityArchived,
    this.getLinkIndex,
    this.onPreviewLocalWork,
    this.onPreviewEntity,
  });

  final BuildContext Function() hostContext;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final void Function(String message) showMessage;
  final HomeShellWiring wiring;
  final HomeVaultCoordinator vault;
  final HomeCatalogCoordinator catalog;
  final HomeNavigationCoordinator navigation;
  final HomeWorkbenchCoordinator workbenchCoord;
  final List<AkashaItem> Function() getItems;
  final void Function(AkashaItem item) addItemInMemory;
  final Future<void> Function() loadItems;
  final Future<void> Function() loadPersonalLibraries;
  final Future<void> Function({bool showFeedback}) autoArchiveWorks;
  final void Function() rebuild;
  final void Function(void Function()) wrapSetState;
  final bool Function() canAddToLibrary;
  final UserCatalogPort userCatalog;
  final void Function(UserCatalogEntity entity, EntityJournalEntry? entry)?
      onEntityArchived;
  final RecordLinkPort Function()? getLinkIndex;
  final void Function(AkashaItem item)? onPreviewLocalWork;
  final void Function(UserCatalogEntity entity)? onPreviewEntity;

  bool get isSyncing => catalog.isSyncing;
  DateTime? get lastSyncTime => catalog.lastSyncTime;
  String get displayName => vault.displayName;
  bool get autoArchiveRegistry => vault.autoArchiveRegistry;
  LibraryTheme get libraryTheme => vault.libraryTheme;

  Future<void> openSearchDialog() async {
    final ctx = hostContext();
    await HomeDialogsFacade.showSearchDialog(
      context: ctx,
      localItems: getItems(),
      userCatalog: userCatalog,
      registry: catalog.registry,
      onSelectLocal: onPreviewLocalWork ?? workbenchCoord.openBrowseItem,
      onSelectRemote: (work) async {
        if (!isMounted()) return;
        final type = EntityIdCodec.typeFromId(work.workId);
        if (type != null && type != EntityAnchorType.work) {
          await _openEntityFromSearch(work.workId);
          return;
        }
        final item = HomeAutoArchive.itemFromRegistryWork(work);
        if (onPreviewLocalWork != null) {
          onPreviewLocalWork!(item);
        } else {
          workbenchCoord.openBrowseItem(item);
        }
      },
      onPromoteCatalogEntity: _promoteCatalogOnlyToArchive,
      onCustomAdd: (query) async {
        if (AkashaFileService().vaultPath == null) {
          showMessage('볼트를 먼저 연결해 주세요.');
          return;
        }
        await HomeDialogsFacade.showCustomAddWithTypePicker(
          context: ctx,
          query: query,
          showMessage: showMessage,
          userCatalog: userCatalog,
          vaultItems: getItems(),
          onWorkSavedToVault: (item) async {
            await AkashaFileService().saveItem(item);
            if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
              await userCatalog.upsert(UserCatalogEntity.fromAkashaItem(item));
            }
            await loadItems();
          },
          onEntitySaved: (result) async {
            final vault = AkashaFileService().vaultPath;
            if (vault == null || vault.isEmpty) {
              showMessage('볼트를 먼저 연결해 주세요.');
              return;
            }
            try {
              final saved = await EntityArchiveService.saveFromAddResult(
                result: result,
                vaultPath: vault,
                userCatalog: userCatalog,
              );
              await loadItems();
              if (!isMounted()) return;

              if (saved.entry != null) {
                await workbenchCoord.openEntity(saved.entity);
              }

              onEntityArchived?.call(saved.entity, saved.entry);
            } on EntityVaultPathConflict catch (e) {
              showMessage(e.userMessage);
            }
          },
        );
      },
      onCatalogPropose: HomeDialogsFacade.catalogProposeCallback(
        context: ctx,
        refreshContributionCount: catalog.syncCatalogContributionCount,
        showMessage: showMessage,
      ),
      onAddLocalToLibrary: canAddToLibrary()
          ? (item) => wiring.libraryUi.showAddToLibraryForItem(
                ctx,
                item: item,
                isCuratedLibraryActive: navigation.isCuratedLibraryActive,
                items: getItems(),
                resolveItemForOpen: workbenchCoord.resolveItemForOpen,
                setState: wrapSetState,
                onCreateLibrary: () => wiring.libraryUi.promptCreateCuratedLibrary(
                  ctx,
                  setState: wrapSetState,
                ),
              )
          : null,
      onAddRemoteToLibrary: canAddToLibrary()
          ? (work) => wiring.libraryUi.addRegistryWorkToLibrary(
                ctx,
                work: work,
                isCuratedLibraryActive: navigation.isCuratedLibraryActive,
                items: getItems(),
                resolveItemForOpen: workbenchCoord.resolveItemForOpen,
                setState: wrapSetState,
                onCreateLibrary: () => wiring.libraryUi.promptCreateCuratedLibrary(
                  ctx,
                  setState: wrapSetState,
                ),
              )
          : null,
    );
  }

  Future<void> _openEntityFromSearch(String entityId) async {
    final entity = await CollectibleOpener.findEntity(userCatalog, entityId);
    if (entity == null) {
      showMessage('「$entityId」을(를) 찾을 수 없습니다.');
      return;
    }
    if (onPreviewEntity != null) {
      onPreviewEntity!(entity);
      return;
    }
    await workbenchCoord.openEntity(entity);
  }

  Future<void> _promoteCatalogOnlyToArchive(RegistryWork work) async {
    final vault = AkashaFileService().vaultPath;
    if (vault == null || vault.isEmpty) {
      showMessage('볼트를 먼저 연결해 주세요.');
      return;
    }

    await userCatalog.load();
    UserCatalogEntity? entity;
    for (final candidate in userCatalog.all) {
      if (candidate.entityId == work.workId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) {
      showMessage('「${work.title}」을(를) 찾을 수 없습니다.');
      return;
    }

    final existing = await const EntityVaultLoader().findByEntityId(
      vault,
      entity.entityId,
    );
    if (existing != null) {
      await _openEntityFromSearch(entity.entityId);
      return;
    }

    try {
      final entry = await EntityArchiveService.promoteCatalogOnly(
        entity: entity,
        vaultPath: vault,
      );
      final mirrored = EntityCatalogSync.mirrorFromJournal(
        draft: entity,
        entry: entry,
      );
      await userCatalog.upsert(mirrored);
      await loadItems();
      if (!isMounted()) return;

      await workbenchCoord.openEntity(mirrored);
      onEntityArchived?.call(mirrored, entry);
    } on EntityVaultPathConflict catch (e) {
      showMessage(e.userMessage);
    }
  }

  Future<void> onAddWorksFromLibraryEdit() async {
    await openSearchDialog();
    await loadItems();
  }

  Future<void> showCustomUrlDialog() async {
    await HomeDialogsFacade.showRegistrySync(
      context: hostContext(),
      isSyncing: isSyncing,
      lastSyncTime: lastSyncTime,
      onSyncNow: catalog.syncRegistry,
      onUrlSaved: catalog.refreshLastSyncTime,
    );
  }

  Future<void> showLibraryThemePicker() async {
    final picked = await HomeDialogsFacade.pickLibraryTheme(
      hostContext(),
      current: libraryTheme,
    );
    if (picked != null && isMounted()) {
      scheduleRebuild(() => vault.libraryTheme = picked);
    }
  }

  Future<void> openCatalogContributionsInbox() async {
    await HomeDialogsFacade.showCatalogContributionsInbox(hostContext());
    await catalog.syncCatalogContributionCount();
  }

  Future<void> openVaultSettingsDialog() async {
    await HomeDialogsFacade.showVaultSettings(
      context: hostContext(),
      displayName: displayName,
      autoArchiveRegistry: autoArchiveRegistry,
      onDisplayNameSaved: (name) =>
          scheduleRebuild(() => vault.displayName = name),
      onAutoArchiveChanged: (enabled) =>
          scheduleRebuild(() => vault.autoArchiveRegistry = enabled),
      runAutoArchive: autoArchiveWorks,
      reloadItems: () async {
        await loadPersonalLibraries();
        await loadItems();
      },
      selectVaultFolder: selectVaultFolder,
      onRegistryVisibilityChanged: rebuild,
    );
  }

  Future<void> openClipboardImportDialog() async {
    await HomeDialogsFacade.showClipboardImport(
      context: hostContext(),
      existingItems: getItems(),
      onItemImportedToVault: (_) async => loadItems(),
      onItemImportedInMemory: addItemInMemory,
    );
  }

  Future<void> openTimelineQuickCapture() async {
    final saved = await HomeDialogsFacade.showTimelineQuickCapture(
      context: hostContext(),
      localItems: getItems(),
      showMessage: showMessage,
    );
    if (saved && isMounted()) navigation.onTimelineQuickCaptureSaved();
  }

  Future<void> openJournalQuickCapture() async {
    final saved = await HomeDialogsFacade.showJournalQuickCapture(
      context: hostContext(),
      showMessage: showMessage,
    );
    if (saved && isMounted()) navigation.onJournalQuickCaptureSaved();
  }

  Future<void> selectVaultFolder() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await AkashaFileService().setVaultPath(selectedDirectory);
        await loadPersonalLibraries();
        await loadItems();
        await autoArchiveWorks();
      }
    } catch (e) {
      if (isMounted()) showMessage('볼트 연결에 실패했습니다: $e');
    }
  }

  Future<void> openAddEntityDialog(EntityAnchorType? forceType) async {
    final ctx = hostContext();
    final vaultPath = AkashaFileService().vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      showMessage('볼트를 먼저 연결해 주세요.');
      return;
    }

    if (forceType == null) {
      await HomeDialogsFacade.showCustomAddWithTypePicker(
        context: ctx,
        query: '',
        showMessage: showMessage,
        userCatalog: userCatalog,
        vaultItems: getItems(),
        onWorkSavedToVault: (item) async {
          await AkashaFileService().saveItem(item);
          if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
            await userCatalog.upsert(UserCatalogEntity.fromAkashaItem(item));
          }
          await loadItems();
        },
        onEntitySaved: _saveEntityResult,
      );
      return;
    }

    if (forceType == EntityAnchorType.work) {
      await HomeDialogsFacade.showAddDialog(
        context: ctx,
        initialTitle: '',
        showMessage: showMessage,
        onSavedToVault: (item) async {
          await AkashaFileService().saveItem(item);
          if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
            await userCatalog.upsert(UserCatalogEntity.fromAkashaItem(item));
          }
          await loadItems();
        },
      );
      return;
    }

    await userCatalog.load();
    if (!ctx.mounted) return;
    final workTitleIndex = EntityTagValidation.buildWorkTitleIndex(
      catalogEntities: userCatalog.all,
      vaultItems: getItems(),
    );

    final addResult = await showAddCatalogEntityDialog(
      ctx,
      entityType: forceType,
      initialTitle: '',
      workTitleIndex: workTitleIndex,
    );
    if (addResult == null || !isMounted()) return;
    await _saveEntityResult(addResult);
  }

  Future<void> _saveEntityResult(CatalogEntityAddResult result) async {
    final vaultPath = AkashaFileService().vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      showMessage('볼트를 먼저 연결해 주세요.');
      return;
    }
    try {
      final saved = await EntityArchiveService.saveFromAddResult(
        result: result,
        vaultPath: vaultPath,
        userCatalog: userCatalog,
      );
      await loadItems();
      if (!isMounted()) return;

      if (saved.entry != null) {
        await workbenchCoord.openEntity(saved.entity);
      }

      onEntityArchived?.call(saved.entity, saved.entry);
    } on EntityVaultPathConflict catch (e) {
      showMessage(e.userMessage);
    }
  }
}
