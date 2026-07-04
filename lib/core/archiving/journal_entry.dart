import 'archive_record_contract.dart';

/// Freeform journal archive record.
class JournalEntry {
  JournalEntry({
    required this.recordId,
    required this.title,
    required this.body,
    required this.addedAt,
    required this.storagePath,
    this.recordMetadata = ArchiveRecordMetadata.empty,
  });

  final String recordId;
  final String title;
  final String body;
  final DateTime addedAt;
  final String storagePath;
  final ArchiveRecordMetadata recordMetadata;
}
