import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/feature_flags.dart';
import '../../../models/akasha_item.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../services/file_service.dart';
import '../../../models/library_theme.dart';
import '../../../services/works_registry.dart';
import '../../../widgets/fusion_search_dialog.dart';
import '../../../widgets/library_theme_picker.dart';
import 'add_work_dialog.dart';
import 'catalog_add_contribution_dialog.dart';
import 'catalog_contributions_inbox_dialog.dart';
import 'clipboard_import_dialog.dart';
import 'prompt_templates_dialog.dart';
import 'registry_sync_dialog.dart';
import 'vault_settings_dialog.dart';

/// 홈 화면 다이얼로그 진입점 — Presentation shell에서 static 호출
class HomeDialogsFacade {
  HomeDialogsFacade._();

  static Future<void> showSearchDialog({
    required BuildContext context,
    required List<AkashaItem> localItems,
    required void Function(AkashaItem item) onSelectLocal,
    required Future<void> Function(RegistryWork work) onSelectRemote,
    required Future<void> Function(String query) onCustomAdd,
    required Future<void> Function(String query)? onCatalogPropose,
    required Future<void> Function(AkashaItem item)? onAddLocalToLibrary,
    required Future<void> Function(RegistryWork work)? onAddRemoteToLibrary,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => FusionSearchDialog(
        localItems: localItems,
        onSelectLocal: onSelectLocal,
        onSelectRemote: onSelectRemote,
        onCustomAdd: onCustomAdd,
        onCatalogPropose: onCatalogPropose,
        onAddLocalToLibrary: onAddLocalToLibrary,
        onAddRemoteToLibrary: onAddRemoteToLibrary,
      ),
    );
  }

  static Future<void> showCatalogContributionsInbox(BuildContext context) async {
    await showCatalogContributionsInboxDialog(context);
  }

  static Future<void> proposeCatalogAdd({
    required BuildContext context,
    required String query,
    required Future<void> Function() refreshContributionCount,
    required void Function(String message) showMessage,
  }) async {
    final saved = await showCatalogAddContributionDialog(
      context,
      initialTitle: query,
      searchQuery: query,
    );
    if (saved == true) {
      await refreshContributionCount();
      showMessage('글로벌 사전 추가 제안이 저장되었습니다. (제안함에서 export)');
    }
  }

  static Future<void> showAddDialog({
    required BuildContext context,
    String? initialTitle,
    required Future<void> Function(AkashaItem item) onSavedToVault,
    required void Function(AkashaItem item) onSavedInMemory,
  }) async {
    final result = await showAddWorkDialog(context, initialTitle: initialTitle);
    if (result == null) return;
    if (AkashaFileService().vaultPath != null) {
      await onSavedToVault(result);
    } else {
      onSavedInMemory(result);
    }
  }

  static Future<void> showVaultSettings({
    required BuildContext context,
    required String displayName,
    required bool autoArchiveRegistry,
    required void Function(String name) onDisplayNameSaved,
    required void Function(bool enabled) onAutoArchiveChanged,
    required Future<void> Function({bool showFeedback}) runAutoArchive,
    required Future<void> Function() reloadItems,
    required Future<void> Function() selectVaultFolder,
    required VoidCallback onRegistryVisibilityChanged,
  }) async {
    await showVaultSettingsDialog(
      context,
      displayName: displayName,
      autoArchiveRegistry: autoArchiveRegistry,
      onDisplayNameSaved: onDisplayNameSaved,
      onAutoArchiveChanged: onAutoArchiveChanged,
      runAutoArchive: runAutoArchive,
      reloadItems: reloadItems,
      selectVaultFolder: selectVaultFolder,
      onRegistryVisibilityChanged: onRegistryVisibilityChanged,
    );
  }

  static Future<void> showClipboardImport({
    required BuildContext context,
    required List<AkashaItem> existingItems,
    required Future<void> Function(AkashaItem item) onItemImportedToVault,
    required void Function(AkashaItem item) onItemImportedInMemory,
  }) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    await showClipboardImportDialog(
      context,
      initialText: data?.text ?? '',
      existingItems: existingItems,
      onItemImported: (item) async {
        if (AkashaFileService().vaultPath != null) {
          await onItemImportedToVault(item);
        } else {
          onItemImportedInMemory(item);
        }
      },
    );
  }

  static Future<void> showRegistrySync({
    required BuildContext context,
    required bool isSyncing,
    required DateTime? lastSyncTime,
    required Future<void> Function() onSyncNow,
    required Future<void> Function() onUrlSaved,
  }) async {
    await showRegistrySyncDialog(
      context,
      isSyncing: isSyncing,
      lastSyncTime: lastSyncTime,
      onSyncNow: onSyncNow,
      onUrlSaved: onUrlSaved,
    );
  }

  static Future<void> showPromptTemplates(BuildContext context) async {
    await showPromptTemplatesDialog(context);
  }

  static Future<LibraryTheme?> pickLibraryTheme(
    BuildContext context, {
    required LibraryTheme current,
  }) {
    return showLibraryThemePicker(context, current: current);
  }

  static Future<void> refreshCatalogContributionCount({
    required void Function(int count) onCount,
  }) async {
    await CatalogContributionService.instance.load();
    onCount(CatalogContributionService.instance.pendingCount);
  }

  static Future<void> Function(String query)? catalogProposeCallback({
    required BuildContext context,
    required Future<void> Function() refreshContributionCount,
    required void Function(String message) showMessage,
  }) {
    if (!FeatureFlags.catalogContributions) return null;
    return (query) => proposeCatalogAdd(
          context: context,
          query: query,
          refreshContributionCount: refreshContributionCount,
          showMessage: showMessage,
        );
  }
}
