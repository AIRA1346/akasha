import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/archive_record.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../data/adapters/vault_archive_record_adapter.dart';
import '../../../core/ports/entity_registry_port.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/akasha_item.dart';
import '../../../models/theme_catalog.dart';
import '../../../services/catalog_contribution_service.dart';
import '../../../services/journal_vault_store.dart';
import '../../../services/person_seed_registry.dart';
import '../../../services/timeline_vault_store.dart';
import '../../../utils/app_l10n.dart';
import '../../../core/ports/registry_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/vault_port.dart';
import '../../../services/works_registry.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../widgets/fusion_search_dialog.dart';
import '../../../widgets/akasha_theme_picker.dart';
import 'add_catalog_entity_dialog.dart';
import 'add_work_dialog.dart';
import 'catalog_add_contribution_dialog.dart';
import 'catalog_contributions_inbox_dialog.dart';
import 'clipboard_import_dialog.dart';
import 'prompt_templates_dialog.dart';
import 'journal_quick_capture_dialog.dart';
import 'timeline_quick_capture_dialog.dart';
import 'vault_settings_dialog.dart';

/// 홈 화면 다이얼로그 진입점 — Presentation shell에서 static 호출
class HomeDialogsFacade {
  HomeDialogsFacade._();

  static Future<void> showSearchDialog({
    required BuildContext context,
    required List<AkashaItem> localItems,
    required UserCatalogPort userCatalog,
    required RegistryPort registry,
    EntityRegistryPort? entityRegistry,
    required void Function(AkashaItem item) onSelectLocal,
    required Future<void> Function(RegistryWork work) onSelectRemote,
    required Future<void> Function(String query) onCustomAdd,
    required Future<void> Function(String query)? onCatalogPropose,
    required Future<void> Function(AkashaItem item)? onAddLocalToLibrary,
    required Future<void> Function(RegistryWork work)? onAddRemoteToLibrary,
    Future<void> Function(RegistryWork work)? onPromoteCatalogEntity,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => FusionSearchDialog(
        localItems: localItems,
        userCatalog: userCatalog,
        registry: registry,
        entityRegistry: entityRegistry ?? PersonSeedRegistry.instance,
        onSelectLocal: onSelectLocal,
        onSelectRemote: onSelectRemote,
        onCustomAdd: (query) => onCustomAdd(query),
        onCatalogPropose: onCatalogPropose,
        onAddLocalToLibrary: onAddLocalToLibrary,
        onAddRemoteToLibrary: onAddRemoteToLibrary,
        onPromoteCatalogEntity: onPromoteCatalogEntity,
      ),
    );
  }

  static Future<void> showCatalogContributionsInbox(
    BuildContext context,
  ) async {
    await showCatalogContributionsInboxDialog(context);
  }

  static Future<void> proposeCatalogAdd({
    required BuildContext context,
    required String query,
    required Future<void> Function() refreshContributionCount,
    required void Function(String message) showMessage,
  }) async {
    final l10n = lookupAppL10n(context);
    final saved = await showCatalogAddContributionDialog(
      context,
      initialTitle: query,
      searchQuery: query,
    );
    if (saved == true) {
      await refreshContributionCount();
      showMessage(
        l10n?.proposalSaved ?? '글로벌 사전 추가 제안이 저장되었습니다. (제안함에서 export)',
      );
    }
  }

  static Future<void> showAddDialog({
    required BuildContext context,
    String? initialTitle,
    required bool isVaultLinked,
    VaultPort? vault,
    required void Function(String message) showMessage,
    required Future<void> Function(AkashaItem item) onSavedToVault,
  }) async {
    final l10n = lookupAppL10n(context);
    if (!isVaultLinked) {
      showMessage(l10n?.validationLinkVaultFirst ?? '볼트를 먼저 연결해 주세요.');
      return;
    }

    final result = await showAddWorkDialog(
      context,
      initialTitle: initialTitle,
      vault: vault,
    );
    if (result == null) return;
    await onSavedToVault(result);
  }

  /// R1 — Work 아카이브 또는 Person/Event/Concept Archive-First 추가.
  static Future<void> showCustomAddWithTypePicker({
    required BuildContext context,
    required String query,
    required bool isVaultLinked,
    VaultPort? vault,
    required void Function(String message) showMessage,
    required Future<void> Function(AkashaItem item) onWorkSavedToVault,
    required Future<void> Function(CatalogEntityAddResult result) onEntitySaved,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    final l10n = lookupAppL10n(context);
    if (!isVaultLinked) {
      showMessage(l10n?.validationLinkVaultFirst ?? '볼트를 먼저 연결해 주세요.');
      return;
    }

    final pickedType = await showCustomEntityTypePicker(
      context,
      initialTitle: query,
    );
    if (pickedType == null || !context.mounted) return;

    if (pickedType == EntityAnchorType.work) {
      await showAddDialog(
        context: context,
        initialTitle: query,
        isVaultLinked: isVaultLinked,
        vault: vault,
        showMessage: showMessage,
        onSavedToVault: onWorkSavedToVault,
      );
      return;
    }

    if (userCatalog != null) {
      await userCatalog.load();
    }
    if (!context.mounted) return;
    final workTitleIndex = userCatalog != null
        ? EntityTagValidation.buildWorkTitleIndex(
            catalogEntities: userCatalog.all,
            vaultItems: vaultItems,
          )
        : const <String>{};

    final addResult = await showAddCatalogEntityDialog(
      context,
      entityType: pickedType,
      initialTitle: query,
      workTitleIndex: workTitleIndex,
    );
    if (addResult == null || !context.mounted) return;
    await onEntitySaved(addResult);
  }

  static Future<void> showVaultSettings({
    required BuildContext context,
    required VaultPort vault,
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
      vault: vault,
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

  /// Phase 4.3 — Timeline quick capture → `vault/timeline/`.
  static Future<bool> showTimelineQuickCapture({
    required BuildContext context,
    required List<AkashaItem> localItems,
    required bool isVaultLinked,
    required void Function(String message) showMessage,
  }) async {
    if (!isVaultLinked) {
      showMessage('볼트를 먼저 연결해 주세요.');
      return false;
    }

    final input = await showTimelineQuickCaptureDialog(
      context,
      linkedWorks: localItems,
    );
    if (input == null || !context.mounted) return false;

    try {
      EntityAnchor? entity;
      final entityId = input.entityId?.trim();
      if (entityId != null && entityId.isNotEmpty) {
        entity = EntityAnchor(
          entityId: entityId,
          type: EntityAnchor.typeForEntityId(entityId),
        );
      }

      final recordId = TimelineVaultStore.generateRecordId(input.occurredAt);
      await VaultArchiveRecordAdapter().save(
        ArchiveRecord(
          recordId: recordId,
          kind: RecordKind.timelineEntry,
          title: input.title,
          timeAnchor: input.occurredAt,
          entity: entity,
        ),
        bodyMarkdown: input.body,
      );

      showMessage('타임라인에 저장했습니다.');
      return true;
    } catch (e) {
      showMessage('타임라인 저장 실패: $e');
      return false;
    }
  }

  /// Wave 3 — freeform journal quick capture → `vault/journal/`.
  static Future<bool> showJournalQuickCapture({
    required BuildContext context,
    required bool isVaultLinked,
    required void Function(String message) showMessage,
  }) async {
    if (!isVaultLinked) {
      showMessage('볼트를 먼저 연결해 주세요.');
      return false;
    }

    final input = await showJournalQuickCaptureDialog(context);
    if (input == null || !context.mounted) return false;

    try {
      final recordId = JournalVaultStore.generateRecordId();
      await VaultArchiveRecordAdapter().save(
        ArchiveRecord(
          recordId: recordId,
          kind: RecordKind.freeformJournal,
          title: input.title,
          timeAnchor: DateTime.now(),
        ),
        bodyMarkdown: input.body,
      );

      showMessage('메모를 저장했습니다.');
      return true;
    } catch (e) {
      showMessage('메모 저장 실패: $e');
      return false;
    }
  }

  static Future<void> showClipboardImport({
    required BuildContext context,
    required List<AkashaItem> existingItems,
    required bool isVaultLinked,
    required Future<void> Function(AkashaItem item) onItemImportedToVault,
    required void Function(AkashaItem item) onItemImportedInMemory,
  }) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    await showClipboardImportDialog(
      context,
      initialText: data?.text ?? '',
      existingItems: existingItems,
      onImport: (item) async {
        if (isVaultLinked) {
          await onItemImportedToVault(item);
        } else {
          onItemImportedInMemory(item);
        }
      },
    );
  }

  static Future<void> showPromptTemplates(BuildContext context) async {
    await showPromptTemplatesDialog(context);
  }

  static Future<String?> pickAppTheme(
    BuildContext context, {
    required String currentThemeId,
    required Map<String, ThemeAccessState> accessByPresetId,
  }) {
    return showAkashaThemePicker(
      context,
      currentThemeId: currentThemeId,
      accessByPresetId: accessByPresetId,
    );
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
