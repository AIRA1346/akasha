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
    onItemImportedToVault: coord.persistWorkToVault,
    onItemImportedInMemory: coord.addItemInMemory,
  );
}

Future<void> _homeDialogsCoordinatorSelectVaultFolder(
  HomeDialogsCoordinator coord,
) async {
  final l10n = lookupAppL10n(coord.hostContext());
  try {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      await coord.vault.setVaultPath(selectedDirectory);
      await coord.loadPersonalLibraries();
      await coord.loadItems();
      await coord.autoArchiveWorks();
    }
  } catch (e) {
    if (coord.isMounted()) {
      coord.showMessage(
        l10n != null
            ? l10n.errorVaultConnectionFailed(e.toString())
            : '볼트 연결에 실패했습니다: $e',
      );
    }
  }
}

Future<void> _homeDialogsCoordinatorCreateDefaultVault(
  HomeDialogsCoordinator coord, {
  required DefaultVaultPathResolver resolver,
}) async {
  String? targetPath;
  final l10n = lookupAppL10n(coord.hostContext());

  try {
    final preferredDir = await resolver.resolvePreferredPath();
    targetPath = p.join(preferredDir, 'AKASHA Vault');
    Directory(targetPath).createSync(recursive: true);
  } catch (_) {
    try {
      final fallbackDir = await resolver.resolveFallbackPath();
      targetPath = p.join(fallbackDir, 'AKASHA Vault');
      Directory(targetPath).createSync(recursive: true);
    } catch (e) {
      if (coord.isMounted()) {
        coord.showMessage(
          l10n != null
              ? l10n.homeVaultCreateFailed(e.toString())
              : '기본 아카이브 생성을 완료하지 못했습니다: $e',
        );
      }
      return;
    }
  }

  try {
    await coord.vault.setVaultPath(targetPath);
    await coord.loadPersonalLibraries();
    await coord.loadItems();
    await coord.autoArchiveWorks();

    if (coord.isMounted()) {
      final context = coord.hostContext();
      if (context.mounted) {
        final dialogL10n = lookupAppL10n(context);
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(
              dialogL10n?.homeVaultCreateDoneTitle ?? '아카이브 생성 완료',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogL10n?.homeVaultCreateDoneBody ??
                      '이 폴더가 AKASHA의 본체입니다. 앱이 아니라, 이 파일들이 당신의 아카이브입니다.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  dialogL10n != null
                      ? dialogL10n.homeVaultCreateDonePath(targetPath!)
                      : '생성된 경로:\n$targetPath',
                  style: TextStyle(
                    color: Theme.of(dialogCtx).disabledColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(dialogL10n?.actionClose ?? '확인'),
              ),
            ],
          ),
        );
      }
    }
  } catch (e) {
    if (coord.isMounted()) {
      coord.showMessage(
        l10n != null
            ? l10n.errorVaultConnectionFailed(e.toString())
            : '볼트 로드 실패: $e',
      );
    }
  }
}
