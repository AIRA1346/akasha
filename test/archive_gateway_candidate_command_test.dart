import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/archive_gateway_candidate.dart';
import 'package:akasha/services/akasha_command_runner.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_gateway_candidate_command.dart';
import 'package:akasha/services/archive_gateway_candidate_service.dart';
import 'package:akasha/services/archive_record_revision_service.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveGatewayCandidateCommand', () {
    late Directory vault;
    late ArchiveCandidateStore candidates;
    late ArchiveGatewayCandidateCommand command;

    setUp(() async {
      vault = await Directory.systemTemp.createTemp('akasha_gateway_command_');
      await _writeAndIndexSource(vault);
      candidates = ArchiveCandidateStore();
      final clock = () => DateTime.utc(2026, 7, 12, 9);
      command = ArchiveGatewayCandidateCommand(
        gateway: ArchiveGatewayCandidateService(
          candidateStore: candidates,
          clock: clock,
        ),
        clock: clock,
      );
    });

    tearDown(() async {
      if (await vault.exists()) await vault.delete(recursive: true);
    });

    test('accepts one structured candidate through the Gateway', () async {
      final revision = await _sourceRevision(vault);

      final result = await command.propose(
        vaultPath: vault.path,
        payload: _payload(revision: revision.value),
      );

      expect(result.ok, isTrue);
      expect(result.applied, isTrue);
      expect(result.candidateId, 'cand_person_command001');
      expect(result.authorityKind, 'user_initiated_session');
      expect(result.authorityId, 'command_session_gwc_command_001');

      final stored = await candidates.load(vault.path);
      expect(stored, hasLength(1));
      expect(stored.single.actorBindingId, 'codex_local_001');
      expect(stored.single.actorLabel, 'Local Codex task');
      expect(stored.single.gatewayAuthorizationId, result.authorityId);
      expect(stored.single.sourceRecordRevision, revision.value);
    });

    test('returns the prior result for an identical command retry', () async {
      final revision = await _sourceRevision(vault);
      final payload = _payload(revision: revision.value);

      final first = await command.propose(
        vaultPath: vault.path,
        payload: payload,
      );
      final retried = await command.propose(
        vaultPath: vault.path,
        payload: payload,
      );

      expect(first.applied, isTrue);
      expect(retried.ok, isTrue);
      expect(retried.alreadyApplied, isTrue);
      expect(await candidates.load(vault.path), hasLength(1));
    });

    test('does not write a candidate from a stale command request', () async {
      final result = await command.propose(
        vaultPath: vault.path,
        payload: _payload(revision: 'v2:sha256:stale;bytes:1'),
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'source_revision_conflict');
      expect(await candidates.load(vault.path), isEmpty);
    });

    test(
      'rejects unknown command fields instead of silently discarding them',
      () async {
        final revision = await _sourceRevision(vault);
        final payload = _payload(revision: revision.value)
          ..['candidate'] = {
            ...(_payload(revision: revision.value)['candidate']
                as Map<String, dynamic>),
            'unrecognizedMeaning': 'must not disappear',
          };

        final result = await command.propose(
          vaultPath: vault.path,
          payload: payload,
        );

        expect(result.ok, isFalse);
        expect(result.errorCode, 'command_payload_invalid');
        expect(await candidates.load(vault.path), isEmpty);
      },
    );

    test('routes structured JSON through the desktop command mode', () async {
      final revision = await _sourceRevision(vault);
      final runner = AkashaCommandRunner(candidateCommand: command);

      final outcome = await runner.execute(
        args: ['candidate', 'propose', '--vault', vault.path],
        stdinText: jsonEncode(_payload(revision: revision.value)),
      );

      expect(outcome.exitCode, 0);
      expect(outcome.response['ok'], isTrue);
      expect(outcome.response['candidateId'], 'cand_person_command001');
      expect(await candidates.load(vault.path), hasLength(1));
    });

    test('keeps command mode closed for unsupported options', () async {
      final runner = AkashaCommandRunner(candidateCommand: command);

      final outcome = await runner.execute(
        args: ['candidate', 'propose', '--anything', 'else'],
        stdinText: '{}',
      );

      expect(outcome.exitCode, 64);
      expect((outcome.response['error'] as Map)['code'], 'command_usage');
      expect(await candidates.load(vault.path), isEmpty);
    });

    test(
      'reads the process command request from one explicit JSON file',
      () async {
        final revision = await _sourceRevision(vault);
        final requestFile = File('${vault.path}/command-request.json');
        await requestFile.writeAsString(
          jsonEncode(_payload(revision: revision.value)),
          flush: true,
        );
        final runner = AkashaCommandRunner(candidateCommand: command);

        final outcome = await runner.executeFromRequestFile(
          args: [
            'candidate',
            'propose',
            '--vault',
            vault.path,
            '--request',
            requestFile.path,
          ],
        );

        expect(outcome.exitCode, 0);
        expect(outcome.response['ok'], isTrue);
        expect(await candidates.load(vault.path), hasLength(1));
      },
    );

    test('writes one JSON command outcome without overwriting it', () async {
      final runner = AkashaCommandRunner(candidateCommand: command);
      final resultFile = File('${vault.path}/command-result.json');
      const outcome = AkashaCommandOutcome(
        exitCode: 2,
        response: {
          'ok': false,
          'error': {'code': 'source_revision_conflict'},
        },
      );

      await runner.writeOutcomeFile(path: resultFile.path, outcome: outcome);

      expect(jsonDecode(await resultFile.readAsString()), outcome.response);
      await expectLater(
        () => runner.writeOutcomeFile(path: resultFile.path, outcome: outcome),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

Future<void> _writeAndIndexSource(Directory vault) async {
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
}

Future<ArchiveRecordRevision> _sourceRevision(Directory vault) =>
    const ArchiveRecordRevisionService().currentForRecordId(
      vaultPath: vault.path,
      recordId: 'rec_source_001',
    );

Map<String, dynamic> _payload({required String revision}) => {
  'operationId': 'gwc_command_001',
  'actorBindingId': 'codex_local_001',
  'actorLabel': 'Local Codex task',
  'sourceRecordId': 'rec_source_001',
  'expectedSourceRevision': revision,
  'candidate': <String, dynamic>{
    'candidateId': 'cand_person_command001',
    'entityType': 'person',
    'title': 'Command candidate',
    'evidence': 'The source explicitly names this person.',
    'confidence': 0.8,
    'aliases': ['Command alias'],
    'tags': ['command'],
    'source': 'agent',
  },
};
