import 'package:akasha/core/archiving/archive_gateway_candidate.dart';
import 'package:akasha/core/archiving/archive_gateway_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveGatewayAppliedReceipt', () {
    test('retains a user-initiated session as the authority route', () {
      final receipt = ArchiveGatewayAppliedReceipt(
        operationId: 'gwc_candidate_001',
        intentFingerprint: 'sha256:abc',
        scope: ArchiveGatewayScope.candidateCreate,
        actorBindingId: 'actor_local_001',
        authority: const ArchiveGatewayAuthorityReference.userInitiatedSession(
          'session_task_001',
        ),
        sourceRecordId: 'rec_source_001',
        sourceRecordRevision: 'v2:sha256:source;bytes:1',
        candidateId: 'cand_person_001',
        candidateRevision: 'sha256:candidate',
        appliedAt: DateTime.utc(2026, 7, 12, 8),
      );

      final encoded = receipt.toJson();
      final decoded = ArchiveGatewayAppliedReceipt.fromJson(encoded);

      expect(encoded['schemaVersion'], 2);
      expect(encoded['authorityKind'], 'user_initiated_session');
      expect(encoded['authorityId'], 'session_task_001');
      expect(encoded.containsKey('grantId'), isFalse);
      expect(
        decoded.authority.kind,
        ArchiveGatewayAuthorityKind.userInitiatedSession,
      );
      expect(decoded.authority.authorityId, 'session_task_001');
      expect(decoded.grantId, isNull);
    });

    test('reads an older grant-only receipt without migration', () {
      final decoded = ArchiveGatewayAppliedReceipt.fromJson({
        'schemaVersion': 1,
        'operationId': 'gwc_candidate_001',
        'intentFingerprint': 'sha256:abc',
        'scope': 'candidate.create',
        'actorBindingId': 'actor_local_001',
        'grantId': 'grant_local_001',
        'sourceRecordId': 'rec_source_001',
        'sourceRecordRevision': 'v2:sha256:source;bytes:1',
        'candidateId': 'cand_person_001',
        'candidateRevision': 'sha256:candidate',
        'appliedAt': '2026-07-12T08:00:00Z',
      });

      expect(decoded.authority.kind, ArchiveGatewayAuthorityKind.durableGrant);
      expect(decoded.authority.authorityId, 'grant_local_001');
      expect(decoded.grantId, 'grant_local_001');
    });
  });
}
