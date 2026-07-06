import 'entity_anchor.dart';
import 'record_kind.dart';

enum ArchiveOperationType {
  createRecord,
  updateFrontmatter,
  appendSection,
  setRating,
  setStatus,
  addTags,
  removeTags,
  addLink,
  promoteCandidate,
  mergeDuplicate,
}

enum ArchiveOperationSource { user, app, agent, importTool, script }

/// Structured intent for app/agent archive writes.
///
/// Vault files remain the source of truth. Operations are the validation layer
/// that keeps future writers from mutating Markdown or indexes arbitrarily.
class ArchiveOperation {
  const ArchiveOperation({
    required this.operationId,
    required this.type,
    required this.recordKind,
    required this.source,
    required this.createdAt,
    this.targetRecordId,
    this.targetEntity,
    this.title,
    this.actor,
    this.expectedRevision,
    this.payload = const {},
  });

  static const int schemaVersion = 1;

  final String operationId;
  final ArchiveOperationType type;
  final RecordKind recordKind;
  final ArchiveOperationSource source;
  final DateTime createdAt;
  final String? targetRecordId;
  final EntityAnchor? targetEntity;
  final String? title;
  final String? actor;
  final String? expectedRevision;
  final Map<String, dynamic> payload;

  String? get effectiveRecordId {
    final explicit = targetRecordId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final entityId = targetEntity?.entityId.trim();
    if (entityId == null || entityId.isEmpty) return null;
    if (recordKind == RecordKind.workJournal ||
        recordKind == RecordKind.entityJournal) {
      return 'rec_$entityId';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'operationId': operationId,
    'type': type.name,
    'recordKind': recordKind.name,
    'source': source.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (targetRecordId != null && targetRecordId!.isNotEmpty)
      'targetRecordId': targetRecordId,
    if (targetEntity != null)
      'targetEntity': {
        'entityId': targetEntity!.entityId,
        'type': targetEntity!.type.name,
      },
    if (title != null && title!.isNotEmpty) 'title': title,
    if (actor != null && actor!.isNotEmpty) 'actor': actor,
    if (expectedRevision != null && expectedRevision!.isNotEmpty)
      'expectedRevision': expectedRevision,
    if (payload.isNotEmpty) 'payload': payload,
  };

  factory ArchiveOperation.fromJson(Map<String, dynamic> json) {
    return ArchiveOperation(
      operationId: json['operationId']?.toString() ?? '',
      type: _enumByName(
        ArchiveOperationType.values,
        json['type']?.toString(),
        ArchiveOperationType.createRecord,
      ),
      recordKind: _enumByName(
        RecordKind.values,
        json['recordKind']?.toString(),
        RecordKind.workJournal,
      ),
      source: _enumByName(
        ArchiveOperationSource.values,
        json['source']?.toString(),
        ArchiveOperationSource.user,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      targetRecordId: json['targetRecordId']?.toString(),
      targetEntity: _targetEntityFromJson(json['targetEntity']),
      title: json['title']?.toString(),
      actor: json['actor']?.toString(),
      expectedRevision: json['expectedRevision']?.toString(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }

  static T _enumByName<T extends Enum>(
    Iterable<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static EntityAnchor? _targetEntityFromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final entityId = map['entityId']?.toString() ?? '';
    if (entityId.trim().isEmpty) return null;
    final type = _enumByName(
      EntityAnchorType.values,
      map['type']?.toString(),
      EntityAnchorType.object,
    );
    return EntityAnchor(entityId: entityId, type: type);
  }
}
