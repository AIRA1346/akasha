import 'dart:io';

import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/archive_gateway_candidate.dart';
import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_gateway_candidate_service.dart';
import 'package:akasha/services/archive_gateway_grant_store.dart';
import 'package:akasha/services/archive_gateway_receipt_store.dart';
import 'package:akasha/services/archive_operation_applied_log.dart';
import 'package:akasha/services/archive_record_revision_service.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveGatewayCandidateService', () {
    late Directory vault;
    late File source;
    late ArchiveGatewayGrantStore grants;
    late ArchiveGatewayReceiptStore receipts;
    late ArchiveCandidateStore candidates;
    late ArchiveGatewayCandidateService service;

    setUp(() async {
      vault = await Directory.systemTemp.createTemp('akasha_gateway_');
      source = await _writeAndIndexSource(vault);
      grants = const ArchiveGatewayGrantStore();
      receipts = const ArchiveGatewayReceiptStore();
      candidates = ArchiveCandidateStore();
      service = ArchiveGatewayCandidateService(
        candidateStore: candidates,
        grantStore: grants,
        receiptStore: receipts,
        clock: () => DateTime.utc(2026, 7, 12, 8),
      );
    });

    tearDown(() async {
      if (await vault.exists()) await vault.delete(recursive: true);
    });

    test('serializes concurrent reuse of one operation id', () async {
      final revision = await _sourceRevision(vault);
      await _allow(grants, vault);

      final results = await Future.wait([
        service.submit(
          vaultPath: vault.path,
          request: _request(revision: revision.value),
        ),
        service.submit(
          vaultPath: vault.path,
          request: _request(
            revision: revision.value,
            candidateId: 'cand_person_gateway002',
            title: 'Concurrent conflicting candidate',
          ),
        ),
      ]);

      expect(results.where((result) => result.isSuccess), hasLength(1));
      expect(
        results.where((result) => result.errorCode == 'operation_id_conflict'),
        hasLength(1),
      );
      expect(await candidates.load(vault.path), hasLength(1));
    });

    test(
      'creates one attributed candidate and an idempotency receipt',
      () async {
        final revision = await _sourceRevision(vault);
        await _allow(grants, vault);
        final request = _request(revision: revision.value);
        final before = await source.readAsString();

        final applied = await service.submit(
          vaultPath: vault.path,
          request: request,
        );

        expect(applied.isSuccess, isTrue);
        expect(applied.applied, isTrue);
        expect(applied.candidate?.sourceOperationId, request.operationId);
        expect(applied.candidate?.actorBindingId, request.actorBindingId);
        expect(applied.candidate?.actorLabel, 'Local tool binding');
        expect(applied.candidate?.gatewayAuthorizationKind, 'durable_grant');
        expect(
          applied.candidate?.gatewayAuthorizationId,
          request.authority.authorityId,
        );
        expect(applied.candidate?.gatewayGrantId, request.authority.grantId);
        expect(applied.candidate?.sourceRecordRevision, revision.value);
        expect(applied.candidate?.createdAt, DateTime.utc(2026, 7, 12, 8));
        expect(applied.receipt?.intentFingerprint, request.intentFingerprint);
        expect(applied.receipt?.sourceRecordRevision, revision.value);
        expect(await source.readAsString(), before);

        final retry = await service.submit(
          vaultPath: vault.path,
          request: request,
        );

        expect(retry.isSuccess, isTrue);
        expect(retry.alreadyApplied, isTrue);
        expect((await candidates.load(vault.path)), hasLength(1));
        expect(
          await receipts.lookup(vault.path, request.operationId),
          isNotNull,
        );
      },
    );

    test('denies a request without a local grant and writes nothing', () async {
      final revision = await _sourceRevision(vault);

      final result = await service.submit(
        vaultPath: vault.path,
        request: _request(revision: revision.value),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'grant_not_found');
      expect(await candidates.load(vault.path), isEmpty);
      expect(await receipts.lookup(vault.path, 'gwc_candidate_001'), isNull);
    });

    test(
      'accepts a candidate from an active user-initiated task without a durable grant',
      () async {
        final revision = await _sourceRevision(vault);
        const authority = ArchiveGatewayAuthorityReference.userInitiatedSession(
          'session_task_001',
        );
        final request = _request(
          revision: revision.value,
          authority: authority,
        );

        final result = await service.submit(
          vaultPath: vault.path,
          request: request,
          userInitiatedSession: _userInitiatedSession(),
        );

        expect(result.isSuccess, isTrue);
        expect(result.candidate?.actorLabel, 'User-started local AI task');
        expect(
          result.candidate?.gatewayAuthorizationKind,
          'user_initiated_session',
        );
        expect(result.candidate?.gatewayAuthorizationId, authority.authorityId);
        expect(result.candidate?.gatewayGrantId, isNull);
        expect(
          result.receipt?.authority.kind,
          ArchiveGatewayAuthorityKind.userInitiatedSession,
        );
        expect(result.receipt?.authority.authorityId, authority.authorityId);
        expect(result.receipt?.grantId, isNull);
        final stored = await candidates.load(vault.path);
        expect(stored, hasLength(1));
        expect(
          stored.single.gatewayAuthorizationKind,
          'user_initiated_session',
        );
        expect(stored.single.gatewayAuthorizationId, authority.authorityId);
        expect(await grants.load(vault.path), isEmpty);
      },
    );

    test('requires the active user-initiated task context', () async {
      final revision = await _sourceRevision(vault);

      final result = await service.submit(
        vaultPath: vault.path,
        request: _request(
          revision: revision.value,
          authority:
              const ArchiveGatewayAuthorityReference.userInitiatedSession(
                'session_task_001',
              ),
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'user_initiated_session_required');
      expect(await candidates.load(vault.path), isEmpty);
      expect(await receipts.lookup(vault.path, 'gwc_candidate_001'), isNull);
    });

    test(
      'keeps a user-started task inside its declared source boundary',
      () async {
        final revision = await _sourceRevision(vault);

        final result = await service.submit(
          vaultPath: vault.path,
          request: _request(
            revision: revision.value,
            authority:
                const ArchiveGatewayAuthorityReference.userInitiatedSession(
                  'session_task_001',
                ),
          ),
          userInitiatedSession: _userInitiatedSession(
            allowedSourceRecordIds: const {'rec_other_001'},
          ),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, 'session_source_not_allowed');
        expect(await candidates.load(vault.path), isEmpty);
      },
    );

    test(
      'denies a candidate after its user-started task has expired',
      () async {
        final revision = await _sourceRevision(vault);

        final result = await service.submit(
          vaultPath: vault.path,
          request: _request(
            revision: revision.value,
            authority:
                const ArchiveGatewayAuthorityReference.userInitiatedSession(
                  'session_task_001',
                ),
          ),
          userInitiatedSession: _userInitiatedSession(
            expiresAt: DateTime.utc(2026, 7, 12, 8),
          ),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, 'user_initiated_session_not_active');
        expect(await candidates.load(vault.path), isEmpty);
      },
    );

    test('binds a user-started task to its declared actor', () async {
      final revision = await _sourceRevision(vault);

      final result = await service.submit(
        vaultPath: vault.path,
        request: _request(
          revision: revision.value,
          authority:
              const ArchiveGatewayAuthorityReference.userInitiatedSession(
                'session_task_001',
              ),
        ),
        userInitiatedSession: _userInitiatedSession(
          actorBindingId: 'actor_other_001',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'session_actor_mismatch');
      expect(await candidates.load(vault.path), isEmpty);
    });

    test(
      'returns an existing receipt after its user-started task has ended',
      () async {
        final revision = await _sourceRevision(vault);
        const authority = ArchiveGatewayAuthorityReference.userInitiatedSession(
          'session_task_001',
        );
        final request = _request(
          revision: revision.value,
          authority: authority,
        );

        final applied = await service.submit(
          vaultPath: vault.path,
          request: request,
          userInitiatedSession: _userInitiatedSession(),
        );
        final retried = await service.submit(
          vaultPath: vault.path,
          request: request,
        );

        expect(applied.applied, isTrue);
        expect(retried.alreadyApplied, isTrue);
        expect(retried.receipt?.authority, isNotNull);
        expect(await candidates.load(vault.path), hasLength(1));
      },
    );

    test('fails closed when persisted grant constraints are malformed', () async {
      final revision = await _sourceRevision(vault);
      final grantFile = File('${vault.path}/system/gateway/grants.json');
      await grantFile.parent.create(recursive: true);
      await grantFile.writeAsString(
        '''{"schemaVersion":1,"grants":[{"grantId":"grant_local_001","actorBindingId":"actor_local_001","scopes":["candidate.create"],"issuedAt":"2026-07-12T00:00:00Z","maxCandidateCount":0,"maxCandidateBytes":1}]}''',
        flush: true,
      );

      final result = await service.submit(
        vaultPath: vault.path,
        request: _request(revision: revision.value),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'grant_state_invalid');
      expect(await candidates.load(vault.path), isEmpty);
    });

    test(
      'denies a stale source revision without creating a candidate',
      () async {
        final observed = await _sourceRevision(vault);
        await _allow(grants, vault);
        await source.writeAsString(
          '${await source.readAsString()}\nchanged',
          flush: true,
        );

        final result = await service.submit(
          vaultPath: vault.path,
          request: _request(revision: observed.value),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, 'source_revision_conflict');
        expect(await candidates.load(vault.path), isEmpty);
        expect(await receipts.lookup(vault.path, 'gwc_candidate_001'), isNull);
      },
    );

    test('rejects reuse of an operation id with a different intent', () async {
      final revision = await _sourceRevision(vault);
      await _allow(grants, vault);
      final first = _request(revision: revision.value);
      final changed = _request(
        revision: revision.value,
        candidateId: 'cand_person_gateway002',
        title: 'Different candidate',
      );

      expect(
        (await service.submit(vaultPath: vault.path, request: first)).isSuccess,
        isTrue,
      );
      final result = await service.submit(
        vaultPath: vault.path,
        request: changed,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'operation_id_conflict');
      expect(await candidates.load(vault.path), hasLength(1));
    });

    test('shares the operation-id namespace with app operations', () async {
      final revision = await _sourceRevision(vault);
      await const ArchiveOperationAppliedLog().appendApplied(
        vaultPath: vault.path,
        operation: ArchiveOperation(
          operationId: 'gwc_candidate_001',
          type: ArchiveOperationType.createRecord,
          recordKind: RecordKind.freeformJournal,
          source: ArchiveOperationSource.app,
          createdAt: DateTime.utc(2026, 7, 12),
        ),
      );

      final result = await service.submit(
        vaultPath: vault.path,
        request: _request(revision: revision.value),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'operation_id_conflict');
      expect(await candidates.load(vault.path), isEmpty);
    });

    test(
      'finishes an exact candidate left without a receipt after interruption',
      () async {
        final revision = await _sourceRevision(vault);
        final request = _request(revision: revision.value);
        final persisted = request.materialize(
          appliedAt: DateTime.utc(2026, 7, 12, 7, 59),
        );
        await candidates.upsert(vaultPath: vault.path, candidate: persisted);

        final result = await service.submit(
          vaultPath: vault.path,
          request: request,
        );

        expect(result.isSuccess, isTrue);
        expect(result.applied, isTrue);
        expect(result.alreadyApplied, isFalse);
        expect(result.candidate?.candidateId, persisted.candidateId);
        expect(result.receipt?.candidateRevision, isNotEmpty);
        expect(await candidates.load(vault.path), hasLength(1));
      },
    );
    test(
      'recovers a grant-era unreceipted candidate after authority fields were added',
      () async {
        final revision = await _sourceRevision(vault);
        final request = _request(revision: revision.value);
        final persisted = request.materialize(
          appliedAt: DateTime.utc(2026, 7, 12, 7, 59),
        );
        final legacyJson = Map<String, dynamic>.from(persisted.toJson())
          ..remove('gatewayAuthorizationKind')
          ..remove('gatewayAuthorizationId')
          ..['schemaVersion'] = 1;
        final legacyCandidate = ArchiveCandidate.fromJson(legacyJson);
        await candidates.upsert(
          vaultPath: vault.path,
          candidate: legacyCandidate,
        );

        final result = await service.submit(
          vaultPath: vault.path,
          request: request,
        );

        expect(result.isSuccess, isTrue);
        expect(result.applied, isTrue);
        expect(result.candidate?.gatewayAuthorizationId, isNull);
        expect(result.receipt?.candidateRevision, isNotEmpty);
      },
    );
    test(
      'denies a candidate request after its local grant is revoked',
      () async {
        final revision = await _sourceRevision(vault);
        await _allow(grants, vault);
        await grants.revoke(
          vaultPath: vault.path,
          grantId: 'grant_local_001',
          revokedAt: DateTime.utc(2026, 7, 12, 7),
        );

        final result = await service.submit(
          vaultPath: vault.path,
          request: _request(revision: revision.value),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, 'grant_not_active');
        expect(await candidates.load(vault.path), isEmpty);
      },
    );
  });
}

Future<File> _writeAndIndexSource(Directory vault) async {
  final file = File('${vault.path}/journals/source.md');
  await file.parent.create(recursive: true);
  await file.writeAsString('''---
record_id: rec_source_001
title: Source note
created_at: 2026-07-12T00:00:00Z
---
Original source body.
''', flush: true);
  await RecordSummaryIndexService().rebuildFromVault(vault.path);
  return file;
}

Future<ArchiveRecordRevision> _sourceRevision(Directory vault) =>
    const ArchiveRecordRevisionService().currentForRecordId(
      vaultPath: vault.path,
      recordId: 'rec_source_001',
    );

Future<void> _allow(ArchiveGatewayGrantStore grants, Directory vault) =>
    grants.upsert(
      vaultPath: vault.path,
      grant: ArchiveGatewayGrant(
        grantId: 'grant_local_001',
        actorBindingId: 'actor_local_001',
        actorLabel: 'Local tool binding',
        scopes: const {ArchiveGatewayScope.candidateCreate},
        issuedAt: DateTime.utc(2026, 7, 12),
      ),
    );

ArchiveGatewayUserInitiatedCandidateSession _userInitiatedSession({
  Set<String> allowedSourceRecordIds = const {'rec_source_001'},
  String actorBindingId = 'actor_local_001',
  DateTime? expiresAt,
}) {
  return ArchiveGatewayUserInitiatedCandidateSession(
    sessionId: 'session_task_001',
    actorBindingId: actorBindingId,
    actorLabel: 'User-started local AI task',
    allowedSourceRecordIds: allowedSourceRecordIds,
    issuedAt: DateTime.utc(2026, 7, 12, 7, 55),
    expiresAt: expiresAt ?? DateTime.utc(2026, 7, 12, 8, 30),
  );
}

ArchiveGatewayCandidateRequest _request({
  required String revision,
  String operationId = 'gwc_candidate_001',
  String candidateId = 'cand_person_gateway001',
  String title = 'Gateway candidate',
  ArchiveGatewayAuthorityReference authority =
      const ArchiveGatewayAuthorityReference.durableGrant('grant_local_001'),
}) {
  return ArchiveGatewayCandidateRequest(
    operationId: operationId,
    actorBindingId: 'actor_local_001',
    authority: authority,
    expectedSourceRevision: revision,
    candidate: ArchiveCandidate(
      candidateId: candidateId,
      entityType: EntityAnchorType.person,
      title: title,
      sourceRecordId: 'rec_source_001',
      evidence: 'The source explicitly names this person.',
      createdAt: DateTime.utc(2026, 7, 12, 7, 55),
      updatedAt: DateTime.utc(2026, 7, 12, 7, 55),
      confidence: 0.8,
      aliases: const ['Candidate'],
      tags: const ['example'],
    ),
  );
}
