import '../core/archiving/archive_candidate.dart';
import '../core/archiving/archive_candidate_validator.dart';
import '../core/archiving/archive_gateway_candidate.dart';
import '../core/archiving/archive_gateway_receipt.dart';
import 'archive_candidate_store.dart';
import 'archive_gateway_grant_store.dart';
import 'archive_gateway_receipt_store.dart';
import 'archive_operation_applied_log.dart';
import 'archive_operation_idempotency_coordinator.dart';
import 'archive_record_revision_service.dart';

class ArchiveGatewayCandidateResult {
  const ArchiveGatewayCandidateResult({
    required this.applied,
    this.alreadyApplied = false,
    this.candidate,
    this.receipt,
    this.errorCode,
    this.message,
  });

  final bool applied;
  final bool alreadyApplied;
  final ArchiveCandidate? candidate;
  final ArchiveGatewayAppliedReceipt? receipt;
  final String? errorCode;
  final String? message;

  bool get isSuccess => (applied || alreadyApplied) && errorCode == null;
}

/// The first executable Archive write Gateway boundary.
///
/// It accepts exactly one authority-checked candidate proposal. It never edits
/// the source Markdown record, creates canonical Records, runs an AI model, or
/// interprets a raw filesystem write as a Gateway action.
class ArchiveGatewayCandidateService {
  ArchiveGatewayCandidateService({
    ArchiveCandidateStore? candidateStore,
    ArchiveGatewayGrantStore? grantStore,
    ArchiveGatewayReceiptStore? receiptStore,
    ArchiveOperationAppliedLog? operationAppliedLog,
    ArchiveRecordRevisionService? revisionService,
    DateTime Function()? clock,
  }) : _candidateStore = candidateStore ?? ArchiveCandidateStore(),
       _grantStore = grantStore ?? const ArchiveGatewayGrantStore(),
       _receiptStore = receiptStore ?? const ArchiveGatewayReceiptStore(),
       _operationAppliedLog =
           operationAppliedLog ?? const ArchiveOperationAppliedLog(),
       _revisionService =
           revisionService ?? const ArchiveRecordRevisionService(),
       _clock = clock ?? DateTime.now;

  final ArchiveCandidateStore _candidateStore;
  final ArchiveGatewayGrantStore _grantStore;
  final ArchiveGatewayReceiptStore _receiptStore;
  final ArchiveOperationAppliedLog _operationAppliedLog;
  final ArchiveRecordRevisionService _revisionService;
  final DateTime Function() _clock;

  Future<ArchiveGatewayCandidateResult> submit({
    required String vaultPath,
    required ArchiveGatewayCandidateRequest request,
    ArchiveGatewayUserInitiatedCandidateSession? userInitiatedSession,
  }) => ArchiveOperationIdempotencyCoordinator.run(
    vaultPath: vaultPath,
    operationId: request.operationId,
    action: () => _submit(
      vaultPath: vaultPath,
      request: request,
      userInitiatedSession: userInitiatedSession,
    ),
  );

  Future<ArchiveGatewayCandidateResult> _submit({
    required String vaultPath,
    required ArchiveGatewayCandidateRequest request,
    required ArchiveGatewayUserInitiatedCandidateSession? userInitiatedSession,
  }) async {
    if (vaultPath.trim().isEmpty) {
      return _failure('vault_path_required', 'Vault path is required.');
    }

    final requestFailure = _validateRequest(request);
    if (requestFailure != null) return requestFailure;

    final fingerprint = request.intentFingerprint;
    final priorReceipt = await _receiptStore.lookup(
      vaultPath,
      request.operationId,
    );
    if (priorReceipt != null) {
      if (priorReceipt.scope != ArchiveGatewayCandidateRequest.scope ||
          priorReceipt.intentFingerprint != fingerprint) {
        return _failure(
          'operation_id_conflict',
          'operationId was already used for a different Gateway intent.',
        );
      }
      return ArchiveGatewayCandidateResult(
        applied: false,
        alreadyApplied: true,
        candidate: await _candidateStore.lookup(
          vaultPath,
          priorReceipt.candidateId,
        ),
        receipt: priorReceipt,
      );
    }

    // Gateway and legacy app operations share an idempotency namespace.
    if (await _operationAppliedLog.lookup(vaultPath, request.operationId) !=
        null) {
      return _failure(
        'operation_id_conflict',
        'operationId was already used by another archive operation.',
      );
    }

    // If a prior run wrote the candidate but was interrupted before it appended
    // its receipt, complete only that exact already-materialized request. This
    // makes the candidate/receipt pair recoverable without trusting a changed
    // source, expired grant, or changed payload as a new operation.
    final existing = await _candidateStore.lookup(
      vaultPath,
      request.candidate.candidateId,
    );
    if (existing != null) {
      return _resumeUnreceiptedCandidate(
        vaultPath: vaultPath,
        request: request,
        existing: existing,
      );
    }

    final now = _clock().toUtc();
    final authorization = await _authorize(
      request: request,
      now: now,
      vaultPath: vaultPath,
      userInitiatedSession: userInitiatedSession,
    );
    if (authorization.failure != null) return authorization.failure!;

    final currentSource = await _revisionService.currentForPhysicalRecordId(
      vaultPath: vaultPath,
      recordId: request.candidate.sourceRecordId,
    );
    if (!currentSource.exists) {
      return _failure(
        'source_record_not_found',
        'The explicitly referenced source record is not available in the Vault index.',
      );
    }
    if (currentSource.value != request.expectedSourceRevision.trim()) {
      return _failure(
        'source_revision_conflict',
        'The source record changed after the request was prepared.',
      );
    }

    final candidate = request.materialize(
      appliedAt: now,
      actorLabel: authorization.actorLabel,
    );
    try {
      await _candidateStore.upsert(vaultPath: vaultPath, candidate: candidate);
    } on ArgumentError catch (error) {
      return _failure(
        'candidate_rejected',
        error.message?.toString() ?? '$error',
      );
    }

    final receipt = _receiptFor(
      request: request,
      candidate: candidate,
      appliedAt: now,
    );
    final appended = await _receiptStore.appendApplied(
      vaultPath: vaultPath,
      receipt: receipt,
    );
    if (appended.intentFingerprint != fingerprint) {
      return _failure(
        'operation_id_conflict',
        'operationId was applied concurrently with a different Gateway intent.',
      );
    }
    return ArchiveGatewayCandidateResult(
      applied: true,
      candidate: candidate,
      receipt: appended,
    );
  }

  Future<ArchiveGatewayCandidateResult> _resumeUnreceiptedCandidate({
    required String vaultPath,
    required ArchiveGatewayCandidateRequest request,
    required ArchiveCandidate existing,
  }) async {
    final expected = request.materialize(
      appliedAt: existing.updatedAt,
      actorLabel: existing.actorLabel,
    );
    if (!ArchiveGatewayIntentFingerprint.candidatesMatchForRecovery(
      existing: existing,
      expected: expected,
    )) {
      return _failure(
        'candidate_id_conflict',
        'candidateId already belongs to a different candidate.',
      );
    }

    final receipt = _receiptFor(
      request: request,
      candidate: existing,
      appliedAt: existing.updatedAt,
    );
    final appended = await _receiptStore.appendApplied(
      vaultPath: vaultPath,
      receipt: receipt,
    );
    if (appended.intentFingerprint != request.intentFingerprint) {
      return _failure(
        'operation_id_conflict',
        'operationId was applied concurrently with a different Gateway intent.',
      );
    }
    return ArchiveGatewayCandidateResult(
      applied: true,
      candidate: existing,
      receipt: appended,
    );
  }

  ArchiveGatewayCandidateResult? _validateRequest(
    ArchiveGatewayCandidateRequest request,
  ) {
    if (!_safeId(request.operationId)) {
      return _failure('operation_id_invalid', 'operationId must be a safe id.');
    }
    if (!_safeId(request.actorBindingId)) {
      return _failure(
        'actor_binding_invalid',
        'actorBindingId must be a safe id.',
      );
    }
    if (!_safeId(request.authority.authorityId)) {
      return _failure(
        'authorization_id_invalid',
        'The Gateway authorization id must be a safe id.',
      );
    }
    if (request.expectedSourceRevision.trim().isEmpty ||
        request.expectedSourceRevision == ArchiveRecordRevision.missing) {
      return _failure(
        'source_revision_required',
        'An observed source record revision is required.',
      );
    }
    if (request.candidate.status != ArchiveCandidateStatus.candidate) {
      return _failure(
        'candidate_status_invalid',
        'Gateway requests may create open candidates only.',
      );
    }
    if (_hasValue(request.candidate.sourceOperationId) ||
        _hasValue(request.candidate.actorBindingId) ||
        _hasValue(request.candidate.gatewayAuthorizationKind) ||
        _hasValue(request.candidate.gatewayAuthorizationId) ||
        _hasValue(request.candidate.gatewayGrantId) ||
        _hasValue(request.candidate.sourceRecordRevision)) {
      return _failure(
        'candidate_gateway_fields_reserved',
        'Gateway-owned candidate fields are assigned by the Gateway only.',
      );
    }
    final validation = ArchiveCandidateValidator.validateCandidate(
      request.candidate,
    );
    if (!validation.isValid) {
      return _failure(
        'candidate_invalid',
        validation.issues
            .where((issue) => issue.severity.name == 'error')
            .map((issue) => issue.code)
            .join(', '),
      );
    }
    return null;
  }

  Future<_GatewayCandidateAuthorization> _authorize({
    required ArchiveGatewayCandidateRequest request,
    required DateTime now,
    required String vaultPath,
    required ArchiveGatewayUserInitiatedCandidateSession? userInitiatedSession,
  }) async {
    switch (request.authority.kind) {
      case ArchiveGatewayAuthorityKind.durableGrant:
        ArchiveGatewayGrant? grant;
        try {
          grant = await _grantStore.lookup(
            vaultPath,
            request.authority.authorityId,
          );
        } on FormatException catch (error) {
          return _GatewayCandidateAuthorization.failure(
            _failure('grant_state_invalid', error.message.toString()),
          );
        }
        final failure = _validateGrant(
          request: request,
          grant: grant,
          now: now,
        );
        if (failure != null) {
          return _GatewayCandidateAuthorization.failure(failure);
        }
        return _GatewayCandidateAuthorization.approved(grant!.actorLabel);
      case ArchiveGatewayAuthorityKind.userInitiatedSession:
        final failure = _validateUserInitiatedSession(
          request: request,
          session: userInitiatedSession,
          now: now,
        );
        if (failure != null) {
          return _GatewayCandidateAuthorization.failure(failure);
        }
        return _GatewayCandidateAuthorization.approved(
          userInitiatedSession!.actorLabel,
        );
    }
  }

  ArchiveGatewayCandidateResult? _validateGrant({
    required ArchiveGatewayCandidateRequest request,
    required ArchiveGatewayGrant? grant,
    required DateTime now,
  }) {
    if (grant == null) {
      return _failure(
        'grant_not_found',
        'No active local Gateway grant exists.',
      );
    }
    if (grant.actorBindingId != request.actorBindingId) {
      return _failure(
        'grant_actor_mismatch',
        'The Gateway grant does not belong to this actor binding.',
      );
    }
    if (!grant.allows(ArchiveGatewayCandidateRequest.scope, now)) {
      return _failure(
        'grant_not_active',
        'The Gateway grant is expired, revoked, or lacks candidate.create.',
      );
    }
    if (grant.maxCandidateCount != 1) {
      return _failure(
        'grant_constraint_invalid',
        'This Gateway slice permits exactly one candidate per request.',
      );
    }
    if (request.encodedCandidateBytes > grant.maxCandidateBytes) {
      return _failure(
        'candidate_too_large',
        'Candidate payload exceeds the local grant byte limit.',
      );
    }
    return null;
  }

  ArchiveGatewayCandidateResult? _validateUserInitiatedSession({
    required ArchiveGatewayCandidateRequest request,
    required ArchiveGatewayUserInitiatedCandidateSession? session,
    required DateTime now,
  }) {
    if (session == null) {
      return _failure(
        'user_initiated_session_required',
        'This candidate request requires its active user-initiated session.',
      );
    }
    if (session.sessionId != request.authority.authorityId) {
      return _failure(
        'user_initiated_session_mismatch',
        'The supplied user-initiated session does not match the request.',
      );
    }
    if (session.actorBindingId != request.actorBindingId) {
      return _failure(
        'session_actor_mismatch',
        'The user-initiated session does not belong to this actor binding.',
      );
    }
    if (!session.isActiveAt(now)) {
      return _failure(
        'user_initiated_session_not_active',
        'The user-initiated candidate intake session has expired.',
      );
    }
    if (!session.allowedSourceRecordIds.contains(
      request.candidate.sourceRecordId,
    )) {
      return _failure(
        'session_source_not_allowed',
        'The candidate source is outside this user-initiated task.',
      );
    }
    if (request.encodedCandidateBytes > session.maxCandidateBytes) {
      return _failure(
        'candidate_too_large',
        'Candidate payload exceeds the user-initiated session byte limit.',
      );
    }
    return null;
  }

  static ArchiveGatewayAppliedReceipt _receiptFor({
    required ArchiveGatewayCandidateRequest request,
    required ArchiveCandidate candidate,
    required DateTime appliedAt,
  }) {
    return ArchiveGatewayAppliedReceipt(
      operationId: request.operationId,
      intentFingerprint: request.intentFingerprint,
      scope: ArchiveGatewayCandidateRequest.scope,
      actorBindingId: request.actorBindingId,
      authority: request.authority,
      sourceRecordId: candidate.sourceRecordId,
      sourceRecordRevision: request.expectedSourceRevision,
      candidateId: candidate.candidateId,
      candidateRevision: ArchiveGatewayIntentFingerprint.candidateRevision(
        candidate,
      ),
      appliedAt: appliedAt,
    );
  }

  static ArchiveGatewayCandidateResult _failure(String code, String message) =>
      ArchiveGatewayCandidateResult(
        applied: false,
        errorCode: code,
        message: message,
      );

  static bool _safeId(String value) =>
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value.trim()) &&
      !value.contains('..');

  static bool _hasValue(String? value) => value?.trim().isNotEmpty ?? false;
}

class _GatewayCandidateAuthorization {
  const _GatewayCandidateAuthorization._({this.actorLabel, this.failure});

  const _GatewayCandidateAuthorization.approved(String? actorLabel)
    : this._(actorLabel: actorLabel);

  const _GatewayCandidateAuthorization.failure(
    ArchiveGatewayCandidateResult failure,
  ) : this._(failure: failure);

  final String? actorLabel;
  final ArchiveGatewayCandidateResult? failure;
}
