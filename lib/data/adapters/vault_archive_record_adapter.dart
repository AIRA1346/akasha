import '../../core/app_vault.dart';
import '../../core/archiving/archive_record.dart';
import '../../core/archiving/archive_record_mapper.dart';
import '../../core/archiving/record_kind.dart';
import '../../core/ports/archive_record_port.dart';
import '../../core/ports/vault_change.dart';
import '../../core/ports/vault_port.dart';
import '../../services/journal_vault_loader.dart';
import '../../services/journal_vault_store.dart';
import '../../services/timeline_vault_loader.dart';
import '../../services/timeline_vault_store.dart';

/// Sanctum vault → [ArchiveRecord] ([ADR-008] Phase 1 + Phase 4 timeline + Wave 3 journal).
class VaultArchiveRecordAdapter implements ArchiveRecordPort {
  VaultArchiveRecordAdapter({
    VaultPort? vault,
    TimelineVaultLoader? timelineLoader,
    TimelineVaultStore? timelineStore,
    JournalVaultLoader? journalLoader,
    JournalVaultStore? journalStore,
  }) : _vault = vault ?? AppVault.port,
       _timelineLoader = timelineLoader ?? const TimelineVaultLoader(),
       _timelineStore = timelineStore ?? const TimelineVaultStore(),
       _journalLoader = journalLoader ?? const JournalVaultLoader(),
       _journalStore = journalStore ?? const JournalVaultStore();

  final VaultPort _vault;
  final TimelineVaultLoader _timelineLoader;
  final TimelineVaultStore _timelineStore;
  final JournalVaultLoader _journalLoader;
  final JournalVaultStore _journalStore;

  @override
  Future<List<ArchiveRecord>> listRecords({Set<RecordKind>? kinds}) async {
    final records = <ArchiveRecord>[];

    final includeVault =
        kinds == null ||
        kinds.contains(RecordKind.workJournal) ||
        kinds.contains(RecordKind.freeformJournal);
    if (includeVault) {
      final items = await _vault.loadAllItems();
      for (final item in items) {
        final record = ArchiveRecordMapper.fromAkashaItem(item);
        if (kinds == null || kinds.contains(record.kind)) {
          records.add(record);
        }
      }
    }

    final includeJournal =
        kinds == null || kinds.contains(RecordKind.freeformJournal);
    if (includeJournal) {
      final journals = await _journalLoader.loadFromVault(_vault.vaultPath);
      records.addAll(journals.map(ArchiveRecordMapper.fromJournalEntry));
    }

    final includeTimeline =
        kinds == null || kinds.contains(RecordKind.timelineEntry);
    if (includeTimeline) {
      final timeline = await _timelineLoader.loadFromVault(_vault.vaultPath);
      records.addAll(timeline.map(ArchiveRecordMapper.fromTimelineEntry));
    }

    records.sort((a, b) {
      final at = a.timeAnchor ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.timeAnchor ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return records;
  }

  @override
  Future<ArchiveRecord?> getById(String recordId) async {
    if (recordId.isEmpty) return null;

    final items = await _vault.loadAllItems();
    for (final item in items) {
      final record = ArchiveRecordMapper.fromAkashaItem(item);
      if (record.recordId == recordId) return record;
    }

    final journals = await _journalLoader.loadFromVault(_vault.vaultPath);
    for (final entry in journals) {
      if (entry.recordId == recordId) {
        return ArchiveRecordMapper.fromJournalEntry(entry);
      }
    }

    final timeline = await _timelineLoader.loadFromVault(_vault.vaultPath);
    for (final entry in timeline) {
      if (entry.recordId == recordId) {
        return ArchiveRecordMapper.fromTimelineEntry(entry);
      }
    }

    return null;
  }

  @override
  Future<void> save(ArchiveRecord record, {String? bodyMarkdown}) async {
    final vaultPath = _vault.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }

    if (record.kind == RecordKind.timelineEntry) {
      final saved = await _timelineStore.save(
        vaultPath: vaultPath,
        record: record,
        body: bodyMarkdown ?? '',
      );
      await _vault.signalVaultChange(
        VaultChangeBatch.fromAbsolutePaths(
          vaultPath: vaultPath,
          upsertedPaths: [saved.storagePath],
        ),
      );
      return;
    }

    if (record.kind == RecordKind.freeformJournal) {
      final saved = await _journalStore.save(
        vaultPath: vaultPath,
        record: record,
        body: bodyMarkdown ?? '',
      );
      await _vault.signalVaultChange(
        VaultChangeBatch.fromAbsolutePaths(
          vaultPath: vaultPath,
          upsertedPaths: [saved.storagePath],
        ),
      );
      return;
    }

    throw UnsupportedError(
      'workJournal via VaultPort.saveItem; timeline/journal via ArchiveRecordPort',
    );
  }

  @override
  Future<void> delete(String recordId) async {
    if (recordId.isEmpty) return;

    final vaultPath = _vault.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }

    final existing = await getById(recordId);
    if (existing == null) return;

    if (existing.kind == RecordKind.timelineEntry) {
      await _timelineStore.delete(vaultPath: vaultPath, recordId: recordId);
      await _signalDeletedRecordPath(vaultPath, existing.storagePath);
      return;
    }

    if (existing.kind == RecordKind.freeformJournal) {
      await _journalStore.delete(vaultPath: vaultPath, recordId: recordId);
      await _signalDeletedRecordPath(vaultPath, existing.storagePath);
      return;
    }

    throw UnsupportedError('timeline/journal only; workJournal via VaultPort');
  }

  Future<void> _signalDeletedRecordPath(String vaultPath, String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) {
      return _vault.signalVaultChanged();
    }
    return _vault.signalVaultChange(
      VaultChangeBatch.fromAbsolutePaths(
        vaultPath: vaultPath,
        deletedPaths: [storagePath],
      ),
    );
  }
}
