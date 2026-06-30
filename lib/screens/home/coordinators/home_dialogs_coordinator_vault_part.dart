part of 'home_dialogs_coordinator.dart';

Future<void> _homeDialogsCoordinatorShowCustomUrlDialog(
  HomeDialogsCoordinator coord,
) async {
  await HomeDialogsFacade.showRegistrySync(
    context: coord.hostContext(),
    isSyncing: coord.isSyncing,
    lastSyncTime: coord.lastSyncTime,
    onSyncNow: coord.catalog.syncRegistry,
    onUrlSaved: coord.catalog.refreshLastSyncTime,
  );
}

Future<void> _homeDialogsCoordinatorShowLibraryThemePicker(
  HomeDialogsCoordinator coord,
) async {
  final picked = await HomeDialogsFacade.pickLibraryTheme(
    coord.hostContext(),
    current: coord.libraryTheme,
  );
  if (picked != null && coord.isMounted()) {
    coord.scheduleRebuild(() => coord.vault.libraryTheme = picked);
  }
}

Future<void> _homeDialogsCoordinatorOpenVaultSettingsDialog(
  HomeDialogsCoordinator coord,
) async {
  await HomeDialogsFacade.showVaultSettings(
    context: coord.hostContext(),
    vault: coord.vault.vault,
    displayName: coord.displayName,
    autoArchiveRegistry: coord.autoArchiveRegistry,
    onDisplayNameSaved: (name) =>
        coord.scheduleRebuild(() => coord.vault.displayName = name),
    onAutoArchiveChanged: (enabled) =>
        coord.scheduleRebuild(() => coord.vault.autoArchiveRegistry = enabled),
    runAutoArchive: coord.autoArchiveWorks,
    reloadItems: () async {
      await coord.loadPersonalLibraries();
      await coord.loadItems();
    },
    selectVaultFolder: () => _homeDialogsCoordinatorSelectVaultFolder(coord),
    onRegistryVisibilityChanged: coord.rebuild,
  );
}

Future<void> _homeDialogsCoordinatorOpenClipboardImportDialog(
  HomeDialogsCoordinator coord,
) async {
  await HomeDialogsFacade.showClipboardImport(
    context: coord.hostContext(),
    existingItems: coord.getItems(),
    isVaultLinked: coord.vault.isVaultLinked,
    onItemImportedToVault: (_) async => coord.loadItems(),
    onItemImportedInMemory: coord.addItemInMemory,
  );
}

Future<void> _homeDialogsCoordinatorSelectVaultFolder(
  HomeDialogsCoordinator coord,
) async {
  try {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      await coord.vault.setVaultPath(selectedDirectory);
      await coord.loadPersonalLibraries();
      await coord.loadItems();
      await coord.autoArchiveWorks();
    }
  } catch (e) {
    if (coord.isMounted()) coord.showMessage('볼트 연결에 실패했습니다: $e');
  }
}
