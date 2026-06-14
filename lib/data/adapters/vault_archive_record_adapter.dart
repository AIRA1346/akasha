import '../../core/archiving/archive_record.dart';
import '../../core/archiving/archive_record_mapper.dart';
import '../../core/archiving/record_kind.dart';
import '../../core/ports/archive_record_port.dart';
import '../../services/file_service.dart';

/// Sanctum vault → [ArchiveRecord] ([ADR-008] Phase 1).
class VaultArchiveRecordAdapter implements ArchiveRecordPort {
  VaultArchiveRecordAdapter({AkashaFileService? fileService})
      : _fileService = fileService ?? AkashaFileService();

  final AkashaFileService _fileService;

  @override
  Future<List<ArchiveRecord>> listRecords({Set<RecordKind>? kinds}) async {
    final items = await _fileService.loadAllItems();
    return items
        .map(ArchiveRecordMapper.fromAkashaItem)
        .where((r) => kinds == null || kinds.contains(r.kind))
        .toList(growable: false);
  }

  @override
  Future<ArchiveRecord?> getById(String recordId) async {
    if (recordId.isEmpty) return null;
    final items = await _fileService.loadAllItems();
    for (final item in items) {
      final record = ArchiveRecordMapper.fromAkashaItem(item);
      if (record.recordId == recordId) return record;
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
