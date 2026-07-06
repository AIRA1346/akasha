import '../../models/entity_id_codec.dart';
import '../../models/user_catalog_entity.dart';
import 'archive_candidate.dart';
import 'archive_operation_validator.dart';
import 'entity_anchor.dart';

class ArchiveCandidatePromotionContext {
  const ArchiveCandidatePromotionContext({
    this.existingEntityIds = const {},
    this.existingTitles = const {},
  });

  final Set<String> existingEntityIds;
  final Set<String> existingTitles;
}

abstract final class ArchiveCandidateValidator {
  static final RegExp _candidateIdPattern = RegExp(r'^cand_[A-Za-z0-9_.:-]+$');

  static ArchiveOperationValidationResult validateCandidate(
    ArchiveCandidate candidate,
  ) {
    final issues = <ArchiveOperationValidationIssue>[];
    _validateBase(candidate, issues);
    return ArchiveOperationValidationResult(issues);
  }

  static ArchiveOperationValidationResult validatePromotion({
    required ArchiveCandidate candidate,
    required EntityAnchor targetEntity,
    ArchiveCandidatePromotionContext context =
        const ArchiveCandidatePromotionContext(),
  }) {
    final issues = <ArchiveOperationValidationIssue>[
      ...validateCandidate(candidate).issues,
    ];

    if (!candidate.isOpen) {
      _error(
        issues,
        'candidate_not_open',
        'Only open candidates can be promoted.',
      );
    }

    final targetId = targetEntity.entityId.trim();
    if (targetId.isEmpty) {
      _error(issues, 'target_entity_required', 'Promotion requires entityId.');
    } else if (targetId.contains('..') || !_isSafeId(targetId)) {
      _error(issues, 'target_entity_unsafe', 'target entityId is unsafe.');
    }

    final inferred = EntityIdCodec.typeFromId(targetId);
    if (inferred != EntityAnchorType.object && inferred != targetEntity.type) {
      _error(
        issues,
        'target_entity_type_mismatch',
        'target entityId does not match declared type.',
      );
    }

    if (targetEntity.type != candidate.entityType) {
      _error(
        issues,
        'candidate_type_mismatch',
        'Promotion target type must match candidate entityType.',
      );
    }

    if (context.existingEntityIds.contains(targetId)) {
      _error(
        issues,
        'target_entity_exists',
        'Promotion target entityId already exists.',
      );
    }

    final normalizedNames = normalizedCandidateNames(candidate);
    if (normalizedNames.any(context.existingTitles.contains)) {
      _error(
        issues,
        'candidate_title_duplicate',
        'Candidate title already exists in archive/catalog.',
      );
    }

    return ArchiveOperationValidationResult(issues);
  }

  static ArchiveCandidatePromotionContext contextFromCatalog(
    Iterable<UserCatalogEntity> entities,
  ) {
    return ArchiveCandidatePromotionContext(
      existingEntityIds: entities.map((entity) => entity.entityId).toSet(),
      existingTitles: {
        for (final entity in entities) normalizeTitle(entity.title),
        for (final entity in entities)
          for (final alias in entity.aliases) normalizeTitle(alias),
      }..remove(''),
    );
  }

  static String normalizeTitle(String raw) {
    var value = raw.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    value = value.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
    value = value.replaceAll(RegExp(r'【[^】]*】'), ' ');
    value = value.replaceAll(RegExp(r'[{}<>]'), ' ');
    value = value.replaceAll(RegExp(r'[_\-:：/\\|.,;!?！？・·]+'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value;
  }

  static Set<String> normalizedCandidateNames(ArchiveCandidate candidate) {
    return {
      normalizeTitle(candidate.title),
      for (final alias in candidate.aliases) normalizeTitle(alias),
    }..remove('');
  }

  static void _validateBase(
    ArchiveCandidate candidate,
    List<ArchiveOperationValidationIssue> issues,
  ) {
    final candidateId = candidate.candidateId.trim();
    if (candidateId.isEmpty) {
      _error(issues, 'candidate_id_required', 'candidateId is required.');
    } else if (!_candidateIdPattern.hasMatch(candidateId) ||
        candidateId.contains('..')) {
      _error(issues, 'candidate_id_unsafe', 'candidateId is unsafe.');
    }

    if (candidate.title.trim().isEmpty) {
      _error(issues, 'candidate_title_required', 'title is required.');
    }

    if (candidate.sourceRecordId.trim().isEmpty) {
      _error(
        issues,
        'candidate_source_record_required',
        'sourceRecordId is required.',
      );
    } else if (!_isSafeId(candidate.sourceRecordId)) {
      _error(
        issues,
        'candidate_source_record_unsafe',
        'sourceRecordId is unsafe.',
      );
    }

    if (candidate.evidence.trim().isEmpty) {
      _error(issues, 'candidate_evidence_required', 'evidence is required.');
    }

    if (candidate.confidence < 0 || candidate.confidence > 1) {
      _error(
        issues,
        'candidate_confidence_range',
        'confidence must be between 0 and 1.',
      );
    }

    final proposed = candidate.proposedEntityId?.trim();
    if (proposed != null && proposed.isNotEmpty) {
      final inferred = EntityIdCodec.typeFromId(proposed);
      if (!_isSafeId(proposed)) {
        _error(
          issues,
          'candidate_proposed_entity_unsafe',
          'proposedEntityId is unsafe.',
        );
      } else if (inferred != EntityAnchorType.object &&
          inferred != candidate.entityType) {
        _error(
          issues,
          'candidate_proposed_entity_type_mismatch',
          'proposedEntityId does not match entityType.',
        );
      }
    }

    final duplicateOf = candidate.duplicateOfEntityId?.trim();
    if (duplicateOf != null && duplicateOf.isNotEmpty) {
      if (!_isSafeId(duplicateOf)) {
        _error(
          issues,
          'candidate_duplicate_entity_unsafe',
          'duplicateOfEntityId is unsafe.',
        );
      }
    }

    if (candidate.entityType == EntityAnchorType.phenomenon) {
      _warning(
        issues,
        'phenomenon_deprecated',
        'phenomenon is deprecated; prefer concept or custom.',
      );
    }
  }

  static bool _isSafeId(String id) =>
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(id.trim()) && !id.contains('..');

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
