import 'entity_anchor.dart';
import 'archive_record_contract.dart';

/// Non-work Entity journal — `vault/entities/{type}/*.md` (Wave 4).
class EntityJournalEntry {
  EntityJournalEntry({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.body,
    required this.addedAt,
    required this.storagePath,
    this.aliases = const [],
    this.tags = const [],
    this.posterPath,
    this.sourceOperationId,
    this.recordMetadata = ArchiveRecordMetadata.empty,
    this.entitySubtype = '',
  });

  final EntityAnchorType entityType;
  final String entityId;
  final String title;
  final String body;
  final DateTime addedAt;
  final String storagePath;
  final List<String> aliases;
  final List<String> tags;
  final String? posterPath;
  final String? sourceOperationId;
  final ArchiveRecordMetadata recordMetadata;
  final String entitySubtype;
}
