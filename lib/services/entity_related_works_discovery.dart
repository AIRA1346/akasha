import '../core/archiving/entity_anchor.dart';
import '../core/ports/record_link_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/entity_related_works.dart';
import 'entity_vault_loader.dart';
import 'file_service.dart';
import 'record_link_navigator.dart';

/// Discovers Work ids linked to an Entity via vault link index (Phase 4 Step 1).
abstract interface class EntityRelatedWorksDiscovery {
  Future<EntityRelatedWorks> discover(String entityId);

  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  );
}

/// incoming (Work→Entity) + outgoing (Entity journal→Work) merge, deduped by workId.
class RecordLinkEntityRelatedWorksDiscovery
    implements EntityRelatedWorksDiscovery {
  RecordLinkEntityRelatedWorksDiscovery({
    required RecordLinkPort linkIndex,
    required List<AkashaItem> vaultItems,
    EntityVaultLoader? vaultLoader,
    String? vaultPath,
    AkashaFileService? fileService,
  })  : _linkIndex = linkIndex,
        _vaultItems = vaultItems,
        _vaultLoader = vaultLoader ?? const EntityVaultLoader(),
        _vaultPath = vaultPath ?? fileService?.vaultPath ?? AkashaFileService().vaultPath;

  final RecordLinkPort _linkIndex;
  final List<AkashaItem> _vaultItems;
  final EntityVaultLoader _vaultLoader;
  final String? _vaultPath;

  @override
  Future<EntityRelatedWorks> discover(String entityId) async {
    final workIds = <String>{};

    final incomingPaths = await _linkIndex.incomingRecordPaths(entityId);
    for (final path in incomingPaths) {
      final workId = await _resolveWorkIdFromRecordPath(path);
      if (workId != null) workIds.add(workId);
    }

    final journal = await _vaultLoader.findByEntityId(_vaultPath, entityId);
    if (journal != null) {
      final outgoing = await _linkIndex.outgoingLinks(journal.storagePath);
      for (final link in outgoing) {
        final targetId = link.targetEntityId;
        if (targetId != null && _isWorkEntityId(targetId)) {
          workIds.add(targetId);
        }
      }
    }

    return EntityRelatedWorks(entityId: entityId, workIds: workIds);
  }

  @override
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    final uniqueIds = entityIds.where((id) => id.isNotEmpty).toSet();
    final entries = await Future.wait(
      uniqueIds.map((id) async => MapEntry(id, await discover(id))),
    );
    return Map.fromEntries(entries);
  }

  Future<String?> _resolveWorkIdFromRecordPath(String storagePath) async {
    final item = await RecordLinkNavigator.findVaultItemForRecordPath(
      storagePath: storagePath,
      vaultItems: _vaultItems,
    );
    if (item != null && item.workId.isNotEmpty) return item.workId;
    return RecordLinkNavigator.readWorkIdFromRecordPath(storagePath);
  }

  static bool _isWorkEntityId(String entityId) =>
      EntityIdCodec.typeFromId(entityId) == EntityAnchorType.work;
}
