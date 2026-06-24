import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/ports/record_link_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/entity_related_works.dart';
import '../utils/work_link_resolution.dart';
import 'entity_vault_loader.dart';
import 'file_service.dart';
import 'record_link_navigator.dart';

/// Discovers Work ids linked to an Entity via vault link index (Phase 4 Step 1).
abstract interface class EntityRelatedWorksDiscovery {
  Future<EntityRelatedWorks> discover(String entityId);

  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  );

  /// Badge count from the last [discover]/[discoverAll] for [entityId], if cached.
  int? cachedIncomingRecordCount(String entityId);

  /// Journal loaded during the last [discover]/[discoverAll], if cached.
  EntityJournalEntry? cachedJournal(String entityId);

  /// Full vault journal map from the last [discoverAll], when available.
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId;

  /// Entity ids linked to [workId] via incoming ∪ outgoing (Cast pre-filter).
  Future<Set<String>> entityIdsForWork(String workId);
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

  final Map<String, int> _incomingRecordCountByEntity = {};
  Map<String, EntityJournalEntry>? _journalByEntityId;

  @override
  int? cachedIncomingRecordCount(String entityId) =>
      _incomingRecordCountByEntity[entityId];

  @override
  EntityJournalEntry? cachedJournal(String entityId) =>
      _journalByEntityId?[entityId];

  @override
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId =>
      _journalByEntityId;

  @override
  Future<EntityRelatedWorks> discover(String entityId) async {
    _incomingRecordCountByEntity.clear();
    return _discoverEntity(entityId);
  }

  @override
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    final uniqueIds = entityIds.where((id) => id.isNotEmpty).toSet();
    if (uniqueIds.isEmpty) return const {};

    _incomingRecordCountByEntity.clear();

    final journals = await _vaultLoader.loadFromVault(_vaultPath);
    final journalByEntityId = <String, EntityJournalEntry>{};
    for (final entry in journals) {
      journalByEntityId.putIfAbsent(entry.entityId, () => entry);
    }
    _journalByEntityId = journalByEntityId;

    final entries = await Future.wait(
      uniqueIds.map(
        (id) async => MapEntry(
          id,
          await _discoverEntity(id, journalByEntityId: journalByEntityId),
        ),
      ),
    );
    return Map.fromEntries(entries);
  }

  @override
  Future<Set<String>> entityIdsForWork(String workId) async {
    if (workId.isEmpty) return const {};

    final linked = <String>{};

    for (final entityId in await _linkIndex.incomingEntityIds()) {
      final paths = await _linkIndex.incomingRecordPaths(entityId);
      for (final path in paths) {
        final resolved = await _resolveWorkIdFromRecordPath(path);
        if (resolved != null &&
            WorkLinkResolution.workIdsReferToSame(resolved, workId)) {
          linked.add(entityId);
          break;
        }
      }
    }

    for (final item in _vaultItems) {
      if (!WorkLinkResolution.workIdsReferToSame(item.workId, workId)) continue;
      final path = item.filePath;
      if (path == null || path.isEmpty) continue;
      final outgoing = await _linkIndex.outgoingLinks(path);
      for (final link in outgoing) {
        final targetId = link.targetEntityId;
        if (targetId == null ||
            targetId.isEmpty ||
            _isWorkEntityId(targetId) ||
            WorkLinkResolution.workIdsReferToSame(targetId, workId)) {
          continue;
        }
        linked.add(targetId);
      }
    }

    final journals = await _vaultLoader.loadFromVault(_vaultPath);
    for (final journal in journals) {
      final outgoing = await _linkIndex.outgoingLinks(journal.storagePath);
      if (outgoing.any((link) {
        final targetId = link.targetEntityId;
        return targetId != null &&
            WorkLinkResolution.workIdsReferToSame(targetId, workId);
      })) {
        linked.add(journal.entityId);
      }
    }

    return linked;
  }

  Future<EntityRelatedWorks> _discoverEntity(
    String entityId, {
    Map<String, EntityJournalEntry>? journalByEntityId,
  }) async {
    final workIds = <String>{};

    final incomingPaths = await _linkIndex.incomingRecordPaths(entityId);
    _incomingRecordCountByEntity[entityId] = incomingPaths.length;
    for (final path in incomingPaths) {
      final workId = await _resolveWorkIdFromRecordPath(path);
      if (workId != null) workIds.add(workId);
    }

    final journal = journalByEntityId != null
        ? journalByEntityId[entityId]
        : await _vaultLoader.findByEntityId(_vaultPath, entityId);
    if (journal != null) {
      _journalByEntityId ??= {};
      _journalByEntityId![entityId] = journal;
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
