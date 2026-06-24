import 'package:flutter/foundation.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../utils/entity_link_neighbors.dart';
import 'entity_detail_vault_sync.dart';
import 'work_detail_vault_sync.dart';
import 'workbench_record_links_loader.dart';

/// EntityDetailWorkspace — incoming·sameDay·neighbors·vault disk sync 상태.
class EntityDetailConnectionsCoordinator {
  EntityDetailConnectionsCoordinator({
    required this.onStateChanged,
    WorkbenchVaultDiskSync? vaultDiskSync,
  }) : vaultDiskSync = vaultDiskSync ?? WorkbenchVaultDiskSync();

  final VoidCallback onStateChanged;
  final WorkbenchVaultDiskSync vaultDiskSync;

  List<String> incomingPaths = const [];
  bool loadingIncoming = false;
  int staleLabelRecordCount = 0;
  List<SameDayRecordRef> sameDayRefs = const [];
  bool loadingSameDay = false;
  EntityLinkNeighbors linkNeighbors = const EntityLinkNeighbors();
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

  Future<EntityJournalEntry?> reloadJournalFromDisk({
    required String? storagePath,
  }) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    final reloaded = await EntityDetailVaultSync.loadJournalFromDisk(storagePath);
    if (reloaded != null) {
      vaultDiskSync.externalChangePending = false;
      refreshDiskMtime(storagePath);
    }
    return reloaded;
  }

  Future<void> loadIncoming({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required RecordLinkPort? linkIndex,
  }) async {
    if (linkIndex == null) return;
    loadingIncoming = true;
    onStateChanged();
    try {
      final snapshot = await WorkbenchRecordLinksLoader.loadIncoming(
        linkIndex: linkIndex,
        recordEntityId: entity.entityId,
        currentTitle: journal?.title ?? entity.title,
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

  Future<void> loadSameDay({
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
  }) async {
    loadingSameDay = true;
    onStateChanged();
    try {
      sameDayRefs = await WorkbenchRecordLinksLoader.loadSameDay(
        anchor: journal?.addedAt ?? entity.addedAt,
        excludePath: journal?.storagePath,
      );
      loadingSameDay = false;
      onStateChanged();
    } catch (_) {
      loadingSameDay = false;
      onStateChanged();
    }
  }

  Future<void> loadLinkNeighbors({
    required UserCatalogEntity entity,
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
      linkNeighbors = await fetchEntityLinkNeighbors(
        entity: entity,
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
    required UserCatalogEntity entity,
    required EntityJournalEntry? journal,
    required UserCatalogPort? userCatalog,
    required RecordLinkPort? linkIndex,
    required List<AkashaItem> vaultItems,
  }) async {
    await Future.wait([
      loadIncoming(entity: entity, journal: journal, linkIndex: linkIndex),
      loadSameDay(entity: entity, journal: journal),
      loadLinkNeighbors(
        entity: entity,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        vaultItems: vaultItems,
      ),
    ]);
  }
}
