import 'entity_anchor.dart';

enum RecordLinkKind {
  referencesEntity,
  referencesRecord,
  sameDay,
}

class RecordLink {
  const RecordLink({
    required this.kind,
    this.targetEntity,
    this.targetRecordId,
  });

  final RecordLinkKind kind;
  final EntityAnchor? targetEntity;
  final String? targetRecordId;
}
