import 'archive_record_contract.dart';
import 'vault_file_revision.dart';

/// Freeform journal archive record.
class JournalEntry {
  JournalEntry({
    required this.recordId,
    required this.title,
    required this.body,
    required this.addedAt,
    required this.storagePath,
    this.recordMetadata = ArchiveRecordMetadata.empty,
    this.openedRevision,
  });

  final String recordId;
  final String title;
  final String body;
  final DateTime addedAt;
  final String storagePath;
  final ArchiveRecordMetadata recordMetadata;
  final VaultFileRevision? openedRevision;
}
