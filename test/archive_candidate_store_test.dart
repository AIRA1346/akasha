import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/archive_candidate_validator.dart';
import 'package:akasha/core/archiving/archive_operation_validator.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveCandidate', () {
    test('round-trips JSON and preserves candidate status', () {
      final candidate = _candidate(
        status: ArchiveCandidateStatus.promoted,
        proposedEntityId: 'pe_u_target01',
      );

      final restored = ArchiveCandidate.fromJson(candidate.toJson());

      expect(restored.candidateId, candidate.candidateId);
      expect(restored.entityType, EntityAnchorType.person);
      expect(restored.status, ArchiveCandidateStatus.promoted);
      expect(restored.proposedEntityId, 'pe_u_target01');
      expect(restored.tags, ['pilot']);
    });

    test('buildCandidateId uses candidate namespace', () {
      expect(
        ArchiveCandidate.buildCandidateId(
          EntityAnchorType.concept,
          suffix: 'abc12345',
        ),
        'cand_concept_abc12345',
      );
    });
  });

  group('ArchiveCandidateValidator', () {
    test('accepts valid open candidate promotion', () {
      final candidate = _candidate();
      final result = ArchiveCandidateValidator.validatePromotion(
        candidate: candidate,
        targetEntity: const EntityAnchor(
          entityId: 'pe_u_target01',
          type: EntityAnchorType.person,
        ),
      );

      expect(result.isValid, isTrue);
    });

    test('rejects promotion when candidate already closed', () {
      final candidate = _candidate(status: ArchiveCandidateStatus.dismissed);
      final result = ArchiveCandidateValidator.validatePromotion(
        candidate: candidate,
        targetEntity: const EntityAnchor(
          entityId: 'pe_u_target01',
          type: EntityAnchorType.person,
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('candidate_not_open'));
    });

    test('rejects existing entity id and duplicate title', () {
      final candidate = _candidate(title: 'Hero');
      final context = ArchiveCandidateValidator.contextFromCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_target01',
          type: EntityAnchorType.person,
          title: 'Hero',
          subtype: MediaCategory.manga,
        ),
      ]);

      final result = ArchiveCandidateValidator.validatePromotion(
        candidate: candidate,
        targetEntity: const EntityAnchor(
          entityId: 'pe_u_target01',
          type: EntityAnchorType.person,
        ),
        context: context,
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('target_entity_exists'));
      expect(_codes(result), contains('candidate_title_duplicate'));
    });

    test('rejects duplicate catalog title through candidate aliases', () {
      final candidate = _candidate(
        title: 'Different',
        aliases: ['Rem (Re:Zero)'],
      );
      final context = ArchiveCandidateValidator.contextFromCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_rem0001',
          type: EntityAnchorType.person,
          title: 'Rem',
          subtype: MediaCategory.manga,
        ),
      ]);

      final result = ArchiveCandidateValidator.validatePromotion(
        candidate: candidate,
        targetEntity: const EntityAnchor(
          entityId: 'pe_u_target01',
          type: EntityAnchorType.person,
        ),
        context: context,
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('candidate_title_duplicate'));
    });

    test('rejects mismatched target entity type', () {
      final result = ArchiveCandidateValidator.validatePromotion(
        candidate: _candidate(),
        targetEntity: const EntityAnchor(
          entityId: 'co_u_target01',
          type: EntityAnchorType.concept,
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('candidate_type_mismatch'));
    });

    test('rejects invalid base candidate confidence and source id', () {
      final result = ArchiveCandidateValidator.validateCandidate(
        _candidate(sourceRecordId: '../rec_bad', confidence: 1.5),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('candidate_source_record_unsafe'));
      expect(_codes(result), contains('candidate_confidence_range'));
    });
  });

  group('ArchiveCandidateStore', () {
    test('round-trips sharded candidates under system/ folder', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        await store.upsert(vaultPath: tempDir.path, candidate: _candidate());

        final loaded = await store.load(tempDir.path);

        expect(loaded, hasLength(1));
        expect(loaded.first.candidateId, 'cand_person_alpha001');
        expect(loaded.first.status, ArchiveCandidateStatus.candidate);

        expect(
          await File(
            '${tempDir.path}/system/candidates/manifest.json',
          ).exists(),
          isTrue,
        );
        final shardDir = Directory('${tempDir.path}/system/candidates/person');
        expect(await shardDir.exists(), isTrue);
        expect(
          await shardDir.list().any(
            (entry) => entry is File && entry.path.endsWith('.json'),
          ),
          isTrue,
        );
        final nameIndexDir = Directory(
          '${tempDir.path}/system/candidates/name_index/person',
        );
        expect(await nameIndexDir.exists(), isTrue);
        expect(
          await File('${tempDir.path}/catalog/candidates.json').exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('loads legacy catalog candidates json for compatibility', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        final legacy = File('${tempDir.path}/catalog/candidates.json');
        await legacy.parent.create(recursive: true);
        await legacy.writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'version': ArchiveCandidateStore.schemaVersion,
            'candidates': [_candidate().toJson()],
          }),
          flush: true,
        );

        final loaded = await store.load(tempDir.path);

        expect(loaded, hasLength(1));
        expect(loaded.single.candidateId, 'cand_person_alpha001');
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test(
      'markPromoted closes candidate and removes it from open list',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_candidates_',
        );
        final store = ArchiveCandidateStore();
        try {
          await store.upsert(vaultPath: tempDir.path, candidate: _candidate());

          await store.markPromoted(
            vaultPath: tempDir.path,
            candidateId: 'cand_person_alpha001',
            entityId: 'pe_u_target01',
            updatedAt: DateTime.utc(2026, 7, 4),
          );

          expect(await store.openCandidates(tempDir.path), isEmpty);
          final promoted = await store.lookup(
            tempDir.path,
            'cand_person_alpha001',
          );
          expect(promoted?.status, ArchiveCandidateStatus.promoted);
          expect(promoted?.proposedEntityId, 'pe_u_target01');
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test('rejects invalid candidate on upsert', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        expect(
          () => store.upsert(
            vaultPath: tempDir.path,
            candidate: _candidate(candidateId: '../bad'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects duplicate open candidate title variants on upsert', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        await store.upsert(vaultPath: tempDir.path, candidate: _candidate());

        await expectLater(
          store.upsert(
            vaultPath: tempDir.path,
            candidate: _candidate(
              candidateId: 'cand_person_beta002',
              title: 'Hero (Pilot)',
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          await File('${tempDir.path}/catalog/candidates.json').exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('duplicate guard survives missing candidate name index', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        await store.upsert(vaultPath: tempDir.path, candidate: _candidate());
        final nameIndex = Directory(
          '${tempDir.path}/system/candidates/name_index',
        );
        if (await nameIndex.exists()) {
          await nameIndex.delete(recursive: true);
        }

        await expectLater(
          store.upsert(
            vaultPath: tempDir.path,
            candidate: _candidate(
              candidateId: 'cand_person_gamma003',
              title: 'Hero',
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('migrates legacy candidate to shards before status update', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_candidates_',
      );
      final store = ArchiveCandidateStore();
      try {
        final legacy = File('${tempDir.path}/catalog/candidates.json');
        await legacy.parent.create(recursive: true);
        await legacy.writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'version': ArchiveCandidateStore.schemaVersion,
            'candidates': [_candidate().toJson()],
          }),
          flush: true,
        );

        await store.markPromoted(
          vaultPath: tempDir.path,
          candidateId: 'cand_person_alpha001',
          entityId: 'pe_u_target01',
          updatedAt: DateTime.utc(2026, 7, 4),
        );

        final promoted = await store.lookup(
          tempDir.path,
          'cand_person_alpha001',
        );
        expect(promoted?.status, ArchiveCandidateStatus.promoted);
        expect(promoted?.proposedEntityId, 'pe_u_target01');
        expect(
          await File(
            '${tempDir.path}/system/candidates/manifest.json',
          ).exists(),
          isTrue,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

ArchiveCandidate _candidate({
  String candidateId = 'cand_person_alpha001',
  EntityAnchorType entityType = EntityAnchorType.person,
  String title = 'Hero',
  String sourceRecordId = 'rec_wk_u_source1',
  String evidence = 'Appears in the third scene.',
  ArchiveCandidateStatus status = ArchiveCandidateStatus.candidate,
  double confidence = 0.8,
  String? proposedEntityId,
  List<String> aliases = const ['The Hero'],
}) {
  return ArchiveCandidate(
    candidateId: candidateId,
    entityType: entityType,
    title: title,
    sourceRecordId: sourceRecordId,
    evidence: evidence,
    status: status,
    confidence: confidence,
    proposedEntityId: proposedEntityId,
    aliases: aliases,
    tags: const ['pilot'],
    createdAt: DateTime.utc(2026, 7, 3),
    updatedAt: DateTime.utc(2026, 7, 3),
  );
}

Set<String> _codes(ArchiveOperationValidationResult result) =>
    result.issues.map((issue) => issue.code).toSet();
