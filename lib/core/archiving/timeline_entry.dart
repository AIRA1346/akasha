import 'archive_record_contract.dart';
import 'vault_file_revision.dart';

/// Timeline archive record.
class TimelineEntry {
  TimelineEntry({
    required this.recordId,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.addedAt,
    required this.storagePath,
    this.entityId,
    this.recordMetadata = ArchiveRecordMetadata.empty,
    this.openedRevision,
  });

  final String recordId;
  final String title;
  final String body;
  final DateTime occurredAt;
  final DateTime addedAt;
  final String storagePath;
  final String? entityId;
  final ArchiveRecordMetadata recordMetadata;
  final VaultFileRevision? openedRevision;
}
