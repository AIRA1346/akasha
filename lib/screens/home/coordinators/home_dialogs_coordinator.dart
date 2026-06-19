import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_id_codec.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../models/work_id_codec.dart';
import '../../../models/library_theme.dart';
import '../../../services/entity_vault_store.dart';
import '../../../services/file_service.dart';
import '../../../services/entity_vault_loader.dart';
import '../dialogs/home_dialogs_facade.dart';
import '../dialogs/entity_journal_dialog.dart';
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
    this.onCatalogEntityAdded,
    this.getLinkIndex,
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
  final void Function(UserCatalogEntity entity)? onCatalogEntityAdded;
  final RecordLinkPort Function()? getLinkIndex;

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
      onSelectLocal: workbenchCoord.openBrowseItem,
      onSelectRemote: (work) async {
        if (!isMounted()) return;
        final type = EntityIdCodec.typeFromId(work.workId);
        if (type != null && type != EntityAnchorType.work) {
          await _openCatalogEntitySheet(work);
          return;
        }
        workbenchCoord.openBrowseItem(
          HomeAutoArchive.itemFromRegistryWork(work),
        );
      },
      onCustomAdd: (query) async {
        if (AkashaFileService().vaultPath == null) {
          showMessage('볼트를 먼저 연결해 주세요.');
          return;
        }
        await HomeDialogsFacade.showCustomAddWithTypePicker(
          context: ctx,
          query: query,
          showMessage: showMessage,
          onWorkSavedToVault: (item) async {
            await AkashaFileService().saveItem(item);
            if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
              await userCatalog.upsert(UserCatalogEntity.fromAkashaItem(item));
            }
            await loadItems();
          },
          onCatalogEntitySaved: (result) async {
            await userCatalog.upsert(result.entity);
            if (result.createJournal) {
              final vault = AkashaFileService().vaultPath;
              if (vault != null && vault.isNotEmpty) {
                await EntityVaultStore().saveCatalogEntity(
                  vaultPath: vault,
                  entity: result.entity,
                  body: result.journalBody,
                );
                await AkashaFileService().signalVaultChanged();
              }
            }
            if (isMounted()) {
              onCatalogEntityAdded?.call(result.entity);
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

  Future<void> _openCatalogEntitySheet(RegistryWork work) async {
    await userCatalog.load();
    UserCatalogEntity? entity;
    for (final candidate in userCatalog.all) {
      if (candidate.entityId == work.workId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) {
      showMessage('catalog에 ${work.workId} 가 없습니다.');
      return;
    }

    final entry = await const EntityVaultLoader().findByEntityId(
      AkashaFileService().vaultPath,
      entity.entityId,
    );
    if (!isMounted()) return;
    await showEntityJournalDialog(
      hostContext(),
      entity: entity,
      entry: entry,
      linkIndex: getLinkIndex?.call(),
      userCatalog: userCatalog,
      vaultItems: getItems(),
      onOpenWork: workbenchCoord.openBrowseItem,
    );
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
}
