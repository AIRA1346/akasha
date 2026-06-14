import '../../core/archiving/archive_record.dart';
import '../../core/archiving/archive_record_mapper.dart';
import '../../core/archiving/record_kind.dart';
import '../../core/ports/archive_record_port.dart';
import '../../services/file_service.dart';
import '../../services/timeline_vault_loader.dart';

/// Sanctum vault → [ArchiveRecord] ([ADR-008] Phase 1 + Phase 4.1 timeline).
class VaultArchiveRecordAdapter implements ArchiveRecordPort {
  VaultArchiveRecordAdapter({
    AkashaFileService? fileService,
    TimelineVaultLoader? timelineLoader,
  })  : _fileService = fileService ?? AkashaFileService(),
        _timelineLoader = timelineLoader ?? const TimelineVaultLoader();

  final AkashaFileService _fileService;
  final TimelineVaultLoader _timelineLoader;

  @override
  Future<List<ArchiveRecord>> listRecords({Set<RecordKind>? kinds}) async {
    final records = <ArchiveRecord>[];

    final includeVault =
        kinds == null || kinds.contains(RecordKind.workJournal) || kinds.contains(RecordKind.freeformJournal);
    if (includeVault) {
      final items = await _fileService.loadAllItems();
      for (final item in items) {
        final record = ArchiveRecordMapper.fromAkashaItem(item);
        if (kinds == null || kinds.contains(record.kind)) {
          records.add(record);
        }
      }
    }

    final includeTimeline = kinds == null || kinds.contains(RecordKind.timelineEntry);
    if (includeTimeline) {
      final timeline = await _timelineLoader.loadFromVault(_fileService.vaultPath);
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

    final items = await _fileService.loadAllItems();
    for (final item in items) {
      final record = ArchiveRecordMapper.fromAkashaItem(item);
      if (record.recordId == recordId) return record;
    }

    final timeline = await _timelineLoader.loadFromVault(_fileService.vaultPath);
    for (final entry in timeline) {
      if (entry.recordId == recordId) {
        return ArchiveRecordMapper.fromTimelineEntry(entry);
      }
    }

    return null;
  }

  @override
  Future<void> save(ArchiveRecord record, {String? bodyMarkdown}) {
    throw UnsupportedError(
      'Phase 1: persist via VaultPort/AkashaItem; ArchiveRecord save in Phase 4+',
    );
  }

  @override
  Future<void> delete(String recordId) {
    throw UnsupportedError(
      'Phase 1: delete via VaultPort; ArchiveRecord delete in Phase 4+',
    );
  }
}
