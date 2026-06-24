import 'package:flutter/foundation.dart';

import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../utils/work_link_neighbors.dart';
import 'work_detail_vault_sync.dart';
import 'work_detail_vault_reload_ops.dart';
import 'workbench_record_links_loader.dart';

/// WorkDetailWorkspace — incoming·sameDay·neighbors·vault disk sync 상태.
class WorkDetailConnectionsCoordinator {
  WorkDetailConnectionsCoordinator({
    required VoidCallback onStateChanged,
    WorkbenchVaultDiskSync? vaultDiskSync,
  })  : onStateChanged = onStateChanged,
        vaultDiskSync = vaultDiskSync ?? WorkbenchVaultDiskSync();

  final VoidCallback onStateChanged;
  final WorkbenchVaultDiskSync vaultDiskSync;

  List<String> incomingPaths = const [];
  bool loadingIncoming = false;
  int staleLabelRecordCount = 0;
  List<SameDayRecordRef> sameDayRefs = const [];
  bool loadingSameDay = false;
  WorkLinkNeighbors linkNeighbors = const WorkLinkNeighbors();
  bool loadingLinkNeighbors = false;

  bool get externalChangePending => vaultDiskSync.externalChangePending;

  void refreshDiskMtime(String? filePath) =>
      vaultDiskSync.refreshDiskMtime(filePath);

  void dismissExternalChange(String? filePath) {
    vaultDiskSync.dismissExternalChange(filePath);
    onStateChanged();
  }

  VaultDiskChangeAction evaluateVaultDiskChange({
    required String? filePath,
    required bool isSaving,
    required bool isDirty,
  }) =>
      vaultDiskSync.evaluateFileChange(
        filePath: filePath,
        isSaving: isSaving,
        isDirty: isDirty,
      );

  Future<AkashaItem?> reloadWorkFromDisk({
    required AkashaItem current,
  }) async {
    final path = current.filePath;
    if (path == null || path.isEmpty) return null;
    final reloaded = await WorkDetailVaultReloadOps.loadWorkJournal(
      path: path,
      titleFallback: current.title,
    );
    if (reloaded != null) {
      vaultDiskSync.externalChangePending = false;
      refreshDiskMtime(path);
    }
    return reloaded;
  }

  Future<void> loadIncoming({
    required AkashaItem work,
    required RecordLinkPort? linkIndex,
  }) async {
    if (linkIndex == null) return;
    loadingIncoming = true;
    onStateChanged();
    try {
      final snapshot = await WorkbenchRecordLinksLoader.loadIncoming(
        linkIndex: linkIndex,
        recordEntityId: work.workId,
        currentTitle: work.title,
      );
      incomingPaths = snapshot.paths;
      staleLabelRecordCount = snapshot.staleLabelRecordCount;
      loadingIncoming = false;
      onStateChanged();
    } catch (_) {
      loadingIncoming = false;
      onStateChanged();
    }
  }

  Future<void> loadSameDay({required AkashaItem work}) async {
    loadingSameDay = true;
    onStateChanged();
    try {
      sameDayRefs = await WorkbenchRecordLinksLoader.loadSameDay(
        anchor: work.addedAt,
        excludePath: work.filePath,
      );
      loadingSameDay = false;
      onStateChanged();
    } catch (_) {
      loadingSameDay = false;
      onStateChanged();
    }
  }

  Future<void> loadLinkNeighbors({
    required AkashaItem work,
    required UserCatalogPort? userCatalog,
    required RecordLinkPort? linkIndex,
    required List<AkashaItem> vaultItems,
  }) async {
    if (userCatalog == null || linkIndex == null) return;
    loadingLinkNeighbors = true;
    onStateChanged();
    try {
      final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: vaultItems,
      );
      linkNeighbors = await fetchWorkLinkNeighbors(
        work: work,
        userCatalog: userCatalog,
        discovery: discovery,
        linkIndex: linkIndex,
        vaultItems: vaultItems,
      );
      loadingLinkNeighbors = false;
      onStateChanged();
    } catch (_) {
      loadingLinkNeighbors = false;
      onStateChanged();
    }
  }

  Future<void> refreshAll({
    required AkashaItem work,
    required UserCatalogPort? userCatalog,
    required RecordLinkPort? linkIndex,
    required List<AkashaItem> vaultItems,
  }) async {
    await Future.wait([
      loadIncoming(work: work, linkIndex: linkIndex),
      loadSameDay(work: work),
      loadLinkNeighbors(
        work: work,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        vaultItems: vaultItems,
      ),
    ]);
  }
}
