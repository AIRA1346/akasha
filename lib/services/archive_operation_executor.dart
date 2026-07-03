import '../core/archiving/archive_candidate.dart';
import '../core/archiving/archive_candidate_validator.dart';
import '../core/archiving/archive_operation.dart';
import '../core/archiving/archive_operation_validator.dart';
import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/enums.dart';
import '../models/user_catalog_entity.dart';
import 'archive_operation_applied_log.dart';
import 'archive_candidate_store.dart';
import 'archive_record_revision_service.dart';
import 'entity_catalog_sync.dart';
import 'entity_vault_store.dart';

class ArchiveOperationExecutionResult {
  const ArchiveOperationExecutionResult({
    required this.applied,
    this.entity,
    this.entry,
    this.candidate,
    this.appliedEntry,
    this.issues = const [],
    this.alreadyApplied = false,
  });

  final bool applied;
  final UserCatalogEntity? entity;
  final EntityJournalEntry? entry;
  final ArchiveCandidate? candidate;
  final ArchiveOperationAppliedEntry? appliedEntry;
  final List<ArchiveOperationValidationIssue> issues;
  final bool alreadyApplied;

  bool get isSuccess => (applied || alreadyApplied) && issues.isEmpty;
}

/// Executes validated archive operations through app-owned write paths.
///
/// This is deliberately small: it starts with candidate promotion so future
/// agent/import writes can move from "intent" to durable vault records safely.
class ArchiveOperationExecutor {
  ArchiveOperationExecutor({
    ArchiveCandidateStore? candidateStore,
    EntityVaultStore? entityVaultStore,
    ArchiveOperationAppliedLog? appliedLog,
    ArchiveRecordRevisionService? revisionService,
  }) : _candidateStore = candidateStore ?? ArchiveCandidateStore(),
       _entityVaultStore = entityVaultStore ?? EntityVaultStore(),
       _appliedLog = appliedLog ?? const ArchiveOperationAppliedLog(),
       _revisionService =
           revisionService ?? const ArchiveRecordRevisionService();

  final ArchiveCandidateStore _candidateStore;
  final EntityVaultStore _entityVaultStore;
  final ArchiveOperationAppliedLog _appliedLog;
  final ArchiveRecordRevisionService _revisionService;

  Future<ArchiveOperationExecutionResult> execute({
    required String vaultPath,
    required ArchiveOperation operation,
    required UserCatalogPort userCatalog,
  }) async {
    if (vaultPath.trim().isEmpty) {
      return _failure('vault_path_required', 'Vault path is required.');
    }

    final validation = ArchiveOperationValidator.validate(operation);
    if (!validation.isValid) {
      return ArchiveOperationExecutionResult(
        applied: false,
        issues: validation.issues,
      );
    }

    final alreadyApplied = await _appliedLog.lookup(
      vaultPath,
      operation.operationId,
    );
    if (alreadyApplied != null) {
      if (alreadyApplied.operationType != operation.type) {
        return _failure(
          'operation_id_conflict',
          'operationId was already applied with a different operation type.',
        );
      }
      return ArchiveOperationExecutionResult(
        applied: false,
        alreadyApplied: true,
        appliedEntry: alreadyApplied,
      );
    }

    return switch (operation.type) {
      ArchiveOperationType.promoteCandidate => _promoteCandidate(
        vaultPath: vaultPath,
        operation: operation,
        userCatalog: userCatalog,
      ),
      _ => ArchiveOperationExecutionResult(
        applied: false,
        issues: const [
          ArchiveOperationValidationIssue(
            severity: ArchiveOperationIssueSeverity.error,
            code: 'operation_not_supported',
            message: 'This operation is not executable yet.',
          ),
        ],
      ),
    };
  }

  Future<ArchiveOperationExecutionResult> _promoteCandidate({
    required String vaultPath,
    required ArchiveOperation operation,
    required UserCatalogPort userCatalog,
  }) async {
    final candidateId = operation.payload['candidateId']?.toString().trim();
    if (candidateId == null || candidateId.isEmpty) {
      return _failure('candidate_required', 'candidateId is required.');
    }

    final targetEntity = operation.targetEntity;
    if (targetEntity == null) {
      return _failure(
        'entity_required',
        'promoteCandidate requires targetEntity.',
      );
    }
    if (targetEntity.type == EntityAnchorType.work) {
      return _failure(
        'work_candidate_not_supported',
        'Work candidates must be promoted through the Work archive path.',
      );
    }

    final conflict = await _validateCreateRevision(
      vaultPath: vaultPath,
      operation: operation,
    );
    if (conflict != null) return conflict;

    final candidate = await _candidateStore.lookup(vaultPath, candidateId);
    if (candidate == null) {
      return _failure('candidate_not_found', 'Candidate does not exist.');
    }

    final promotionCandidate = _candidateForPromotion(candidate, operation);

    await userCatalog.load();
    final promotionValidation = ArchiveCandidateValidator.validatePromotion(
      candidate: promotionCandidate,
      targetEntity: targetEntity,
      context: ArchiveCandidateValidator.contextFromCatalog(userCatalog.all),
    );
    if (!promotionValidation.isValid) {
      return ArchiveOperationExecutionResult(
        applied: false,
        candidate: candidate,
        issues: promotionValidation.issues,
      );
    }

    final entity = _entityFromCandidate(
      candidate: promotionCandidate,
      targetEntity: targetEntity,
      operation: operation,
    );
    final entry = await _entityVaultStore.saveCatalogEntity(
      vaultPath: vaultPath,
      entity: entity,
      body: _bodyForPromotion(candidate, operation),
    );
    final mirrored = EntityCatalogSync.mirrorFromJournal(
      draft: entity,
      entry: entry,
    );
    await userCatalog.upsert(mirrored);
    await _candidateStore.markPromoted(
      vaultPath: vaultPath,
      candidateId: candidate.candidateId,
      entityId: targetEntity.entityId,
    );
    final appliedEntry = await _appliedLog.appendApplied(
      vaultPath: vaultPath,
      operation: operation,
      recordPath: entry.storagePath,
    );
    final closed = await _candidateStore.lookup(vaultPath, candidateId);

    return ArchiveOperationExecutionResult(
      applied: true,
      entity: mirrored,
      entry: entry,
      candidate: closed,
      appliedEntry: appliedEntry,
    );
  }

  static UserCatalogEntity _entityFromCandidate({
    required ArchiveCandidate candidate,
    required EntityAnchor targetEntity,
    required ArchiveOperation operation,
  }) {
    return UserCatalogEntity.userLocal(
      entityId: targetEntity.entityId,
      type: targetEntity.type,
      title: candidate.title,
      subtype: _subtypeFromPayload(operation.payload),
      aliases: List<String>.from(candidate.aliases),
      tags: List<String>.from(candidate.tags),
      addedAt: operation.createdAt.toUtc(),
    );
  }

  static ArchiveCandidate _candidateForPromotion(
    ArchiveCandidate candidate,
    ArchiveOperation operation,
  ) {
    final title = operation.title?.trim();
    if (title == null || title.isEmpty) return candidate;
    return candidate.copyWith(title: title);
  }

  static MediaCategory _subtypeFromPayload(Map<String, dynamic> payload) {
    final raw =
        payload['subtype']?.toString() ?? payload['category']?.toString();
    for (final category in MediaCategory.values) {
      if (category.name == raw) return category;
    }
    return MediaCategory.manga;
  }

  static String _bodyForPromotion(
    ArchiveCandidate candidate,
    ArchiveOperation operation,
  ) {
    final body = operation.payload['body']?.toString().trim() ?? '';
    if (body.isNotEmpty) return body;
    return '## Evidence\n\n${candidate.evidence.trim()}';
  }

  Future<ArchiveOperationExecutionResult?> _validateCreateRevision({
    required String vaultPath,
    required ArchiveOperation operation,
  }) async {
    final current = await _revisionService.currentForOperation(
      vaultPath: vaultPath,
      operation: operation,
    );
    final expected = operation.expectedRevision?.trim();

    if (expected != null && expected.isNotEmpty && expected != current.value) {
      return _conflict(
        expectedRevision: expected,
        currentRevision: current.value,
      );
    }

    if (current.exists) {
      return _conflict(
        expectedRevision: expected ?? ArchiveRecordRevision.missing,
        currentRevision: current.value,
      );
    }

    return null;
  }

  static ArchiveOperationExecutionResult _failure(String code, String message) {
    return ArchiveOperationExecutionResult(
      applied: false,
      issues: [
        ArchiveOperationValidationIssue(
          severity: ArchiveOperationIssueSeverity.error,
          code: code,
          message: message,
        ),
      ],
    );
  }

  static ArchiveOperationExecutionResult _conflict({
    required String expectedRevision,
    required String currentRevision,
  }) {
    return ArchiveOperationExecutionResult(
      applied: false,
      issues: [
        ArchiveOperationValidationIssue(
          severity: ArchiveOperationIssueSeverity.error,
          code: 'operation_conflict',
          message:
              'Record revision conflict: expected $expectedRevision but found $currentRevision.',
        ),
      ],
    );
  }
}
