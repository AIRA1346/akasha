import '../../models/enums.dart';
import '../../models/work_id_codec.dart';
import '../../services/works_registry.dart';
import 'entity_anchor.dart';
import 'record_kind.dart';

/// YAML frontmatter entity metadata ([vault-layout-v2 §4]).
class EntityFrontmatter {
  const EntityFrontmatter({
    required this.entityType,
    required this.entityId,
    required this.subtype,
    this.recordKind = RecordKind.workJournal,
  });

  final EntityAnchorType entityType;
  final String entityId;
  final MediaCategory subtype;
  final RecordKind recordKind;

  /// Wave 2 — work journal from [AkashaItem] (no entity_type field on item).
  factory EntityFrontmatter.forWorkItem({
    required String workId,
    required MediaCategory category,
  }) {
    return EntityFrontmatter(
      entityType: EntityAnchorType.work,
      entityId: workId,
      subtype: category,
      recordKind: RecordKind.workJournal,
    );
  }

  static EntityFrontmatter inferFromYaml(
    Map<dynamic, dynamic> yamlMap, {
    required MediaCategory categoryFallback,
  }) {
    final entityIdRaw = yamlMap['entity_id']?.toString().trim() ?? '';
    final workIdRaw = WorksRegistry.resolveWorkId(
      yamlMap['work_id']?.toString() ?? '',
    );

    final entityId = entityIdRaw.isNotEmpty ? entityIdRaw : workIdRaw;

    EntityAnchorType entityType;
    final typeRaw = yamlMap['entity_type']?.toString().trim();
    if (typeRaw != null && typeRaw.isNotEmpty) {
      entityType = _parseEntityType(typeRaw);
    } else if (entityId.isNotEmpty) {
      entityType = EntityAnchor.typeForEntityId(entityId);
    } else {
      entityType = EntityAnchorType.work;
    }

    if (entityId.isNotEmpty &&
        EntityAnchor.typeForEntityId(entityId) == EntityAnchorType.work) {
      entityType = EntityAnchorType.work;
    }

    final subtype = _parseSubtype(
      yamlMap['subtype']?.toString() ?? yamlMap['category']?.toString(),
      categoryFallback,
    );

    final recordKind = _parseRecordKind(yamlMap['record_kind']?.toString());

    return EntityFrontmatter(
      entityType: entityType,
      entityId: entityId,
      subtype: subtype,
      recordKind: recordKind,
    );
  }

  /// Lazy v2 fields to merge into YAML (Wave 2+).
  Map<String, String> toLazyWriteFields() {
    if (entityId.isEmpty) return const {};

    if (entityType == EntityAnchorType.work) {
      return {
        'entity_type': entityType.name,
        'entity_id': entityId,
        'subtype': subtype.name,
        'record_kind': recordKind.name,
      };
    }

    if (recordKind == RecordKind.entityJournal) {
      return {
        'entity_type': entityType.name,
        'entity_id': entityId,
        'record_kind': recordKind.name,
      };
    }

    return const {};
  }

  EntityAnchor? toEntityAnchor() {
    if (entityId.isEmpty) return null;
    return EntityAnchor(entityId: entityId, type: entityType);
  }

  static EntityAnchorType _parseEntityType(String raw) {
    for (final type in EntityAnchorType.values) {
      if (type.name == raw) return type;
    }
    return EntityAnchorType.work;
  }

  static MediaCategory _parseSubtype(String? raw, MediaCategory fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    for (final cat in MediaCategory.values) {
      if (cat.name == raw) return cat;
    }
    return fallback;
  }

  static RecordKind _parseRecordKind(String? raw) {
    if (raw == null || raw.isEmpty) return RecordKind.workJournal;
    for (final kind in RecordKind.values) {
      if (kind.name == raw) return kind;
    }
    return RecordKind.workJournal;
  }

  /// Resolved work_id for AkashaItem — Wave 2 work journals only.
  String get resolvedWorkId {
    if (entityType != EntityAnchorType.work) return entityId;
    if (entityId.isNotEmpty) return entityId;
    return '';
  }

  bool get isWorkMasterId =>
      entityId.isNotEmpty && WorkIdCodec.isMasterFormat(entityId);
}
