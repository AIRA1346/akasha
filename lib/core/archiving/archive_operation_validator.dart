import '../../models/entity_id_codec.dart';
import 'archive_operation.dart';
import 'entity_anchor.dart';
import 'record_kind.dart';

enum ArchiveOperationIssueSeverity { error, warning }

class ArchiveOperationValidationIssue {
  const ArchiveOperationValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
  });

  final ArchiveOperationIssueSeverity severity;
  final String code;
  final String message;
}

class ArchiveOperationValidationResult {
  const ArchiveOperationValidationResult(this.issues);

  final List<ArchiveOperationValidationIssue> issues;

  bool get isValid => !issues.any(
    (issue) => issue.severity == ArchiveOperationIssueSeverity.error,
  );

  List<ArchiveOperationValidationIssue> get errors => issues
      .where((issue) => issue.severity == ArchiveOperationIssueSeverity.error)
      .toList(growable: false);

  List<ArchiveOperationValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ArchiveOperationIssueSeverity.warning)
      .toList(growable: false);
}

abstract final class ArchiveOperationValidator {
  static final RegExp _safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
  static final RegExp _candidateIdPattern = RegExp(r'^cand_[A-Za-z0-9_.:-]+$');

  static const Set<String> _forbiddenPayloadKeys = {
    'path',
    'filePath',
    'storagePath',
    'vaultPath',
    'absolutePath',
    'relativePath',
  };

  static const Set<String> _immutableFrontmatterKeys = {
    'schema_version',
    'schemaVersion',
    'record_kind',
    'recordKind',
    'record_id',
    'recordId',
    'entity_id',
    'entityId',
    'entity_type',
    'entityType',
    'work_id',
    'workId',
  };

  static ArchiveOperationValidationResult validate(ArchiveOperation operation) {
    final issues = <ArchiveOperationValidationIssue>[];

    _validateCommon(operation, issues);
    switch (operation.type) {
      case ArchiveOperationType.createRecord:
        _validateCreateRecord(operation, issues);
      case ArchiveOperationType.updateFrontmatter:
        _validateUpdateFrontmatter(operation, issues);
      case ArchiveOperationType.appendSection:
        _validateAppendSection(operation, issues);
      case ArchiveOperationType.setRating:
        _validateSetRating(operation, issues);
      case ArchiveOperationType.setStatus:
        _validateSetStatus(operation, issues);
      case ArchiveOperationType.addTags:
      case ArchiveOperationType.removeTags:
        _validateTags(operation, issues);
      case ArchiveOperationType.addLink:
        _validateAddLink(operation, issues);
      case ArchiveOperationType.promoteCandidate:
        _validatePromoteCandidate(operation, issues);
      case ArchiveOperationType.mergeDuplicate:
        _validateMergeDuplicate(operation, issues);
    }

    return ArchiveOperationValidationResult(issues);
  }

  static void _validateCommon(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _validateSafeId(
      operation.operationId,
      issues,
      code: 'operation_id_required',
      label: 'operationId',
    );

    final targetRecordId = operation.targetRecordId?.trim();
    if (targetRecordId != null && targetRecordId.isNotEmpty) {
      _validateSafeId(
        targetRecordId,
        issues,
        code: 'target_record_id_unsafe',
        label: 'targetRecordId',
      );
    }

    final actor = operation.actor?.trim();
    if (actor != null && actor.isNotEmpty && actor.length > 120) {
      _error(issues, 'actor_too_long', 'actor must stay concise.');
    }

    _validateTargetEntity(operation.targetEntity, issues);
    _validatePayloadJson(operation.payload, issues);
    _validateForbiddenPayloadKeys(operation.payload, issues);
  }

  static void _validateCreateRecord(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    final title = operation.title?.trim() ?? '';
    if (title.isEmpty) {
      _error(issues, 'title_required', 'createRecord requires a title.');
    } else if (title.length > 300) {
      _error(issues, 'title_too_long', 'title must be 300 characters or less.');
    }

    if ((operation.recordKind == RecordKind.workJournal ||
            operation.recordKind == RecordKind.entityJournal) &&
        operation.targetEntity == null) {
      _error(
        issues,
        'entity_required',
        'work/entity records require a targetEntity.',
      );
    }
  }

  static void _validateUpdateFrontmatter(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    if (operation.payload.isEmpty) {
      _error(
        issues,
        'payload_required',
        'updateFrontmatter requires frontmatter fields.',
      );
    }
    for (final key in operation.payload.keys) {
      if (_immutableFrontmatterKeys.contains(key)) {
        _error(
          issues,
          'immutable_frontmatter',
          'updateFrontmatter must not change identity field "$key".',
        );
      }
    }
  }

  static void _validateAppendSection(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    final body = operation.payload['body']?.toString().trim() ?? '';
    if (body.isEmpty) {
      _error(
        issues,
        'section_body_required',
        'appendSection requires non-empty body.',
      );
    }
    final heading = operation.payload['heading']?.toString().trim();
    if (heading != null && heading.length > 120) {
      _error(
        issues,
        'section_heading_too_long',
        'appendSection heading must be 120 characters or less.',
      );
    }
  }

  static void _validateSetRating(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    final raw = operation.payload['rating'];
    final rating = raw is num ? raw.toDouble() : null;
    if (rating == null || rating < 0 || rating > 5) {
      _error(
        issues,
        'rating_range',
        'setRating requires numeric rating between 0 and 5.',
      );
    }
  }

  static void _validateSetStatus(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    final status = operation.payload['status']?.toString().trim() ?? '';
    if (status.isEmpty) {
      _error(issues, 'status_required', 'setStatus requires status.');
    }
  }

  static void _validateTags(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    final tags = operation.payload['tags'];
    if (tags is! List || tags.isEmpty) {
      _error(issues, 'tags_required', '${operation.type.name} requires tags.');
      return;
    }
    for (final tag in tags) {
      final text = tag.toString().trim();
      if (text.isEmpty) {
        _error(issues, 'tag_blank', 'tags must not contain blank values.');
      } else if (text.length > 80) {
        _error(issues, 'tag_too_long', 'tag "$text" is too long.');
      }
    }
  }

  static void _validateAddLink(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _requireRecordTarget(operation, issues);
    final targetEntityId =
        operation.payload['targetEntityId']?.toString().trim() ?? '';
    if (targetEntityId.isEmpty) {
      _error(
        issues,
        'link_target_required',
        'addLink requires targetEntityId.',
      );
      return;
    }
    _validateEntityId(targetEntityId, null, issues);
  }

  static void _validatePromoteCandidate(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    final candidateId =
        operation.payload['candidateId']?.toString().trim() ?? '';
    if (candidateId.isEmpty) {
      _error(
        issues,
        'candidate_required',
        'promoteCandidate requires candidateId.',
      );
    } else if (!_candidateIdPattern.hasMatch(candidateId) ||
        candidateId.contains('..')) {
      _error(
        issues,
        'candidate_id_unsafe',
        'promoteCandidate candidateId is unsafe.',
      );
    }
    if (operation.targetEntity == null) {
      _error(
        issues,
        'entity_required',
        'promoteCandidate requires promoted targetEntity.',
      );
    }
  }

  static void _validateMergeDuplicate(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    final canonicalId =
        operation.payload['canonicalEntityId']?.toString().trim() ?? '';
    final duplicateId =
        operation.payload['duplicateEntityId']?.toString().trim() ?? '';
    if (canonicalId.isEmpty || duplicateId.isEmpty) {
      _error(
        issues,
        'merge_ids_required',
        'mergeDuplicate requires canonicalEntityId and duplicateEntityId.',
      );
      return;
    }
    if (canonicalId == duplicateId) {
      _error(issues, 'merge_ids_same', 'mergeDuplicate ids must be different.');
    }
    _validateEntityId(canonicalId, null, issues);
    _validateEntityId(duplicateId, null, issues);
  }

  static void _requireRecordTarget(
    ArchiveOperation operation,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    if (operation.effectiveRecordId == null) {
      _error(
        issues,
        'target_record_required',
        '${operation.type.name} requires targetRecordId or targetEntity.',
      );
    }
  }

  static void _validateTargetEntity(
    EntityAnchor? entity,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    if (entity == null) return;
    _validateEntityId(entity.entityId, entity.type, issues);
    if (entity.type == EntityAnchorType.phenomenon) {
      _warning(
        issues,
        'phenomenon_deprecated',
        'phenomenon is deprecated; prefer concept or custom.',
      );
    }
  }

  static void _validateEntityId(
    String entityId,
    EntityAnchorType? declaredType,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    _validateSafeId(
      entityId,
      issues,
      code: 'entity_id_unsafe',
      label: 'entityId',
    );
    final inferred = EntityIdCodec.typeFromId(entityId);
    if (declaredType != null &&
        inferred != EntityAnchorType.custom &&
        inferred != declaredType) {
      _error(
        issues,
        'entity_type_mismatch',
        'entityId "$entityId" does not match ${declaredType.name}.',
      );
    }
  }

  static void _validateSafeId(
    String id,
    List<ArchiveOperationValidationIssue> issues, {
    required String code,
    required String label,
  }) {
    final value = id.trim();
    if (value.isEmpty) {
      _error(issues, code, '$label is required.');
      return;
    }
    if (!_safeIdPattern.hasMatch(value) || value.contains('..')) {
      _error(issues, code, '$label contains unsafe characters.');
    }
  }

  static void _validatePayloadJson(
    Map<String, dynamic> payload,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    if (!_isJsonSafe(payload)) {
      _error(
        issues,
        'payload_json_safe',
        'payload must contain only JSON-safe values.',
      );
    }
  }

  static bool _isJsonSafe(Object? value, [int depth = 0]) {
    if (depth > 8) return false;
    if (value == null || value is String || value is num || value is bool) {
      return true;
    }
    if (value is List) {
      return value.every((item) => _isJsonSafe(item, depth + 1));
    }
    if (value is Map) {
      return value.entries.every(
        (entry) => entry.key is String && _isJsonSafe(entry.value, depth + 1),
      );
    }
    return false;
  }

  static void _validateForbiddenPayloadKeys(
    Object? value,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (_forbiddenPayloadKeys.contains(key) || key.startsWith('.')) {
          _error(
            issues,
            'payload_path_forbidden',
            'payload must not carry path/runtime key "$key".',
          );
        }
        _validateForbiddenPayloadKeys(entry.value, issues);
      }
    } else if (value is List) {
      for (final item in value) {
        _validateForbiddenPayloadKeys(item, issues);
      }
    }
  }

  static void _error(
    List<ArchiveOperationValidationIssue> issues,
    String code,
    String message,
  ) {
    issues.add(
      ArchiveOperationValidationIssue(
        severity: ArchiveOperationIssueSeverity.error,
        code: code,
        message: message,
      ),
    );
  }

  static void _warning(
    List<ArchiveOperationValidationIssue> issues,
    String code,
    String message,
  ) {
    issues.add(
      ArchiveOperationValidationIssue(
        severity: ArchiveOperationIssueSeverity.warning,
        code: code,
        message: message,
      ),
    );
  }
}
