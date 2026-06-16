import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ports/vault_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/library_theme.dart';
import '../../../services/entitlement_service.dart';
import '../../../services/library_theme_preferences.dart';
import '../../../services/user_preferences.dart';
import '../../../services/user_registry_preferences.dart';
import '../home_auto_archive.dart';
import '../home_vault_loader.dart';

/// 볼트·사용자 설정·auto-archive (E2-2).
class HomeVaultCoordinator {
  HomeVaultCoordinator({
    required this.vault,
    required this.isMounted,
    required this.scheduleRebuild,
    required this.onVaultItemsSynced,
    required this.prefetchRegistry,
  });

  final VaultPort vault;
  final bool Function() isMounted;
  final void Function(void Function()) scheduleRebuild;
  final void Function(List<AkashaItem> items) onVaultItemsSynced;
  final Future<void> Function() prefetchRegistry;

  List<AkashaItem> items = [];
  String displayName = UserPreferences.defaultDisplayName;
  bool autoArchiveRegistry = false;
  LibraryTheme libraryTheme = LibraryTheme.classic;

  StreamSubscription<void>? vaultUpdateSubscription;
  Timer? vaultReloadDebounce;

  Future<void> initService() async {
    await vault.init();
  }

  Future<void> loadPreferences() async {
    displayName = await UserPreferences.getDisplayName();
    autoArchiveRegistry = await UserPreferences.isAutoArchiveRegistryEnabled();
    await UserRegistryPreferences.instance.load();
    await EntitlementService.instance.load();
    libraryTheme = await LibraryThemePreferences.load();
    if (isMounted()) scheduleRebuild(() {});
  }

  Future<void> loadItems() async {
    final loadedItems = await HomeVaultLoader.loadItems(vault);
    if (!isMounted()) return;
    scheduleRebuild(() => items = loadedItems);
    onVaultItemsSynced(loadedItems);
  }

  Future<void> autoArchiveRegistryWorks({
    bool showFeedback = false,
    void Function(String message)? showMessage,
  }) async {
    final count = await HomeAutoArchive.run(
      prefetchFilters: prefetchRegistry,
      showFeedback: showFeedback,
      showMessage: showMessage,
    );
    if (count > 0) await loadItems();
  }

  Future<void> runStartupAutoArchiveIfNeeded() async {
    if (vault.vaultPath != null && autoArchiveRegistry) {
      await autoArchiveRegistryWorks();
    }
  }

  void bindVaultWatch({required VoidCallback onVaultChanged}) {
    vaultUpdateSubscription?.cancel();
    vaultUpdateSubscription = vault.onVaultUpdated.listen((_) {
      vaultReloadDebounce?.cancel();
      vaultReloadDebounce = Timer(const Duration(milliseconds: 400), () {
        if (isMounted()) onVaultChanged();
      });
    });
  }

  void dispose() {
    vaultReloadDebounce?.cancel();
    vaultUpdateSubscription?.cancel();
  }
}
