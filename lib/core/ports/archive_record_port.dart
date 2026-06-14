import '../archiving/archive_record.dart';
import '../archiving/record_kind.dart';

/// vault · (Phase 4) timeline 공통 Record 계약 ([ADR-008]).
abstract class ArchiveRecordPort {
  Future<List<ArchiveRecord>> listRecords({Set<RecordKind>? kinds});

  Future<ArchiveRecord?> getById(String recordId);

  Future<void> save(ArchiveRecord record, {String? bodyMarkdown});

  Future<void> delete(String recordId);
}
