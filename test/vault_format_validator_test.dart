import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/timeline_entry_parser.dart';

import '../tool/vault_format_validator.dart';

/// Conformance suite for the standalone vault format validator (spec v3).
///
/// The validator intentionally has no dependency on app code; these tests
/// also feed the app's own serializer output through it, so a drift between
/// implementation and specification fails here first.
void main() {
  VaultFormatReport validate(String content, {String path = 'records/x.md'}) {
    final report = VaultFormatReport();
    VaultFormatValidator().validateRecordContent(content, path, report);
    return report;
  }

  List<String> codes(VaultFormatReport report) =>
      report.issues.map((issue) => issue.code).toList(growable: false);

  group('conforming v3 records', () {
    test('valid work journal has no issues', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_wk_u_abc12345"
record_kind: workJournal
entity_type: work
entity_id: "wk_u_abc12345"
work_id: "wk_u_abc12345"
title: "작품"
category: manga
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
added_at: "2026-07-06T12:00:00.000Z"
source: "user"
links:
  - relation: "appears_in"
    target_id: "pe_u_abc12345"
  - relation: "u:voiced_by"
    target_id: "pe_u_zzz99999"
---
본문
''');
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.v3Count, 1);
    });

    test('timeline entry with wall-clock occurred_at and no entity is valid',
        () {
      final report = validate('''
---
schema_version: 3
record_id: "tl_20260705_abc123"
record_kind: timelineEntry
title: "그날 밤"
occurred_at: "2026-07-05T22:30:00.000"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "agent"
---
본문
''');
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('legacy v1/v2 record without schema_version stays readable', () {
      final report = validate('''
---
record_kind: entityJournal
entity_type: person
entity_id: "pe_u_abc12345"
title: "인물"
added_at: "2026-06-19T12:00:00.000Z"
---
본문
''');
      expect(report.errors, isEmpty);
      expect(report.legacyCount, 1);
    });
  });

  group('spec violations', () {
    test('missing source and timestamps on v3 record', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_pe_u_abc12345"
record_kind: entityJournal
entity_type: person
entity_id: "pe_u_abc12345"
title: "인물"
---
본문
''');
      expect(
        codes(report),
        containsAll([
          'source_required',
          'created_at_required',
          'updated_at_required',
        ]),
      );
    });

    test('entity_id prefix must match entity_type (§3)', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_pe_u_abc12345"
record_kind: entityJournal
entity_type: person
entity_id: "ob_u_abc12345"
title: "인물"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
---
본문
''');
      expect(codes(report), contains('entity_id_prefix_mismatch'));
    });

    test('unknown top-level entity_type is an error (§3)', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_xx_u_abc12345"
record_kind: entityJournal
entity_type: phenomenon
entity_id: "pe_u_abc12345"
title: "?"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
---
본문
''');
      expect(codes(report), contains('entity_type_unknown'));
    });

    test('system timestamp without Z is an error (§2.2)', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_wk_u_abc12345"
record_kind: workJournal
entity_type: work
entity_id: "wk_u_abc12345"
title: "작품"
created_at: "2026-07-06T12:00:00.000"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
---
본문
''');
      expect(codes(report), contains('created_at_not_utc'));
    });

    test('occurred_at with Z downgrades to legacy warning (§2.3)', () {
      final report = validate('''
---
schema_version: 3
record_id: "tl_1"
record_kind: timelineEntry
title: "t"
occurred_at: "2026-07-05T13:30:00.000Z"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
---
본문
''');
      expect(report.errors, isEmpty);
      expect(codes(report), contains('occurred_at_legacy_zone'));
    });

    test('non-conforming link relation is a warning (§4.1)', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_wk_u_abc12345"
record_kind: workJournal
entity_type: work
entity_id: "wk_u_abc12345"
title: "작품"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
links:
  - relation: "voiced_by"
    target_id: "pe_u_abc12345"
---
본문
''');
      expect(report.errors, isEmpty);
      expect(codes(report), contains('link_relation_nonconforming'));
    });

    test('unknown record_kind is an error (§2.1)', () {
      final report = validate('''
---
schema_version: 3
record_id: "rec_1"
record_kind: diary
title: "t"
created_at: "2026-07-06T12:00:00.000Z"
updated_at: "2026-07-06T12:00:00.000Z"
source: "user"
---
본문
''');
      expect(codes(report), contains('record_kind_unknown'));
    });
  });

  group('app serializer output conforms to the spec', () {
    test('EntityJournalParser.serialize passes the standalone validator', () {
      final content = EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_abc12345',
        title: '나츠키 스바루',
        body: '본문',
      );

      final report = validate(content, path: 'entities/person/pe_u_abc12345.md');
      expect(report.errors, isEmpty,
          reason: 'app entity serializer must emit spec-conforming records: '
              '${report.issues}');
    });

    test('TimelineEntryParser.serialize passes the standalone validator', () {
      final content = TimelineEntryParser.serialize(
        recordId: 'tl_20260705_abc123',
        title: '그날 밤',
        body: '본문',
        occurredAt: DateTime(2026, 7, 5, 22, 30),
        entityId: 'wk_u_abc12345',
      );

      final report = validate(content, path: 'timeline/tl_20260705_abc123.md');
      expect(report.errors, isEmpty,
          reason: 'app timeline serializer must emit spec-conforming records: '
              '${report.issues}');
      expect(codes(report), isNot(contains('occurred_at_legacy_zone')));
    });
  });
}
