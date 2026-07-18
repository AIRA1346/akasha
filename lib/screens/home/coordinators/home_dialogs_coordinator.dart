import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_id_codec.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../models/catalog_entity_add_result.dart';
import '../../../models/work_id_codec.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../services/entity_archive_service.dart';
import '../../../services/entity_catalog_sync.dart';
import '../../../services/entity_vault_loader.dart';
import '../../../services/entity_vault_path_conflict.dart';
import '../../../services/open_collectible.dart';
import '../../../services/akasha_theme_controller.dart';
import '../dialogs/home_dialogs_facade.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../../../utils/entity_tag_validation.dart';
import '../../../services/default_vault_path_resolver.dart';
import '../home_auto_archive.dart';
import 'home_catalog_coordinator.dart';
import 'home_navigation_coordinator.dart';
import 'home_shell_wiring.dart';
import 'home_vault_coordinator.dart';
import 'home_workbench_coordinator.dart';
import '../../../utils/app_l10n.dart';

part 'home_dialogs_coordinator_search_part.dart';
part 'home_dialogs_coordinator_vault_part.dart';
part 'home_dialogs_coordinator_capture_part.dart';
part 'home_dialogs_coordinator_entity_part.dart';

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

  String get displayName => vault.displayName;
  bool get autoArchiveRegistry => vault.autoArchiveRegistry;

  /// Persists a Work and updates only the active Home representation. The
  /// bounded Work browse projection receives its own precise Vault change, so
  /// this must not fall back to loading every archived Work.
  Future<void> persistWorkToVault(AkashaItem item) async {
    await vault.saveVaultItem(item);
    if (WorkIdCodec.isUserLocalWorkId(item.workId)) {
      await userCatalog.upsert(UserCatalogEntity.fromAkashaItem(item));
    }
    await workbenchCoord.onWorkbenchWorkSaved(item, silent: true);
  }

  Future<void> openSearchDialog() =>
      _homeDialogsCoordinatorOpenSearchDialog(this);

  Future<void> onAddWorksFromLibraryEdit() =>
      _homeDialogsCoordinatorOnAddWorksFromLibraryEdit(this);

  Future<void> showAppThemePicker() =>
      _homeDialogsCoordinatorShowAppThemePicker(this);

  Future<void> openCatalogContributionsInbox() =>
      _homeDialogsCoordinatorOpenCatalogContributionsInbox(this);

  Future<void> openVaultSettingsDialog() =>
      _homeDialogsCoordinatorOpenVaultSettingsDialog(this);

  Future<void> openClipboardImportDialog() =>
      _homeDialogsCoordinatorOpenClipboardImportDialog(this);

  Future<void> openTimelineQuickCapture() =>
      _homeDialogsCoordinatorOpenTimelineQuickCapture(this);

  Future<void> openJournalQuickCapture() =>
      _homeDialogsCoordinatorOpenJournalQuickCapture(this);

  Future<void> selectVaultFolder() =>
      _homeDialogsCoordinatorSelectVaultFolder(this);

  Future<void> createDefaultVault({
    DefaultVaultPathResolver resolver = const DefaultVaultPathResolver(),
  }) => _homeDialogsCoordinatorCreateDefaultVault(this, resolver: resolver);

  Future<void> openAddEntityDialog(EntityAnchorType? forceType) =>
      _homeDialogsCoordinatorOpenAddEntityDialog(this, forceType);
}
