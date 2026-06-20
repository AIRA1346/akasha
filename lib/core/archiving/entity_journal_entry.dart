import 'entity_anchor.dart';

/// Non-work Entity journal — `vault/entities/{type}/*.md` (Wave 4).
class EntityJournalEntry {
  EntityJournalEntry({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.body,
    required this.addedAt,
    required this.storagePath,
    this.tags = const [],
    this.posterPath,
  });

  final EntityAnchorType entityType;
  final String entityId;
  final String title;
  final String body;
  final DateTime addedAt;
  final String storagePath;
  final List<String> tags;
  final String? posterPath;
}
