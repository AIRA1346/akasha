import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/entity_vault_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vault;
  const loader = EntityVaultLoader();

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_entity_load_issues_');
  });

  tearDown(() async {
    if (await vault.exists()) await vault.delete(recursive: true);
  });

  Future<File> writeEntity({
    required String id,
    required String title,
    String subdir = 'person',
  }) async {
    final file = File(p.join(vault.path, 'entities', subdir, '$id.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: id,
        title: title,
        body: 'body',
      ),
      flush: true,
    );
    return file;
  }

  test('keeps good entry and reports yaml_parse_failed for broken YAML', () async {
    await writeEntity(id: 'pe_u_good0001', title: 'Good');
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_bad_yaml.md'),
    );
    await bad.parent.create(recursive: true);
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_bad_yaml"\n'
      'title: [unterminated\n'
      '---\n\n'
      'SECRET_MARKDOWN_BODY_SHOULD_NOT_LEAK\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries.map((e) => e.entityId), ['pe_u_good0001']);
    expect(detailed.issues, hasLength(1));
    expect(detailed.issues.single.errorCode, 'yaml_parse_failed');
    expect(detailed.issues.single.severity, EntityVaultIssueSeverity.error);
    expect(
      detailed.issues.single.relativePath.replaceAll('\\', '/'),
      'entities/person/pe_u_bad_yaml.md',
    );
    expect(
      detailed.issues.single.toString(),
      isNot(contains('SECRET_MARKDOWN_BODY_SHOULD_NOT_LEAK')),
    );

    final compat = await loader.loadFromVault(vault.path);
    expect(compat.map((e) => e.entityId), ['pe_u_good0001']);
  });

  test('corrupt-only vault is empty entries but non-empty issues', () async {
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_only_bad.md'),
    );
    await bad.parent.create(recursive: true);
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_only_bad"\n'
      'title: [broken\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final emptyVault = await Directory.systemTemp.createTemp(
      'akasha_entity_empty_',
    );
    try {
      final empty = await loader.loadFromVaultWithIssues(emptyVault.path);
      expect(empty.entries, isEmpty);
      expect(empty.issues, isEmpty);

      final corrupted = await loader.loadFromVaultWithIssues(vault.path);
      expect(corrupted.entries, isEmpty);
      expect(corrupted.issues, isNotEmpty);
      expect(corrupted.issues.single.errorCode, 'yaml_parse_failed');
    } finally {
      if (await emptyVault.exists()) {
        await emptyVault.delete(recursive: true);
      }
    }
  });

  test('unclosed frontmatter is frontmatter_invalid', () async {
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_unclosed.md'),
    );
    await bad.parent.create(recursive: true);
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_unclosed"\n'
      'title: "Unclosed"\n'
      'body without closing fence\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries, isEmpty);
    expect(detailed.issues.single.errorCode, 'frontmatter_invalid');
    expect(detailed.issues.single.severity, EntityVaultIssueSeverity.error);
  });

  test('missing frontmatter is warning/ignored without failing the load', () async {
    await writeEntity(id: 'pe_u_keep0001', title: 'Keep');
    final plain = File(
      p.join(vault.path, 'entities', 'person', 'plain_note.md'),
    );
    await plain.writeAsString('just a note without frontmatter\n', flush: true);

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries.map((e) => e.entityId), ['pe_u_keep0001']);
    expect(detailed.issues, hasLength(1));
    expect(detailed.issues.single.errorCode, 'frontmatter_missing');
    expect(
      detailed.issues.single.severity,
      anyOf(EntityVaultIssueSeverity.warning, EntityVaultIssueSeverity.ignored),
    );
  });

  test('non-entity record_kind is unexpected_record_kind, not corruption', () async {
    final other = File(
      p.join(vault.path, 'entities', 'person', 'jr_u_other.md'),
    );
    await other.parent.create(recursive: true);
    await other.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.freeformJournal.name}\n'
      'entity_id: "jr_u_other"\n'
      'title: "Other kind"\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries, isEmpty);
    expect(detailed.issues.single.errorCode, 'unexpected_record_kind');
    expect(
      detailed.issues.single.severity,
      anyOf(EntityVaultIssueSeverity.warning, EntityVaultIssueSeverity.ignored),
    );
  });

  test('matching record_kind with empty entity_id is entity_id_missing', () async {
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_noid.md'),
    );
    await bad.parent.create(recursive: true);
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: ""\n'
      'title: "No Id"\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries, isEmpty);
    expect(detailed.issues.single.errorCode, 'entity_id_missing');
    expect(detailed.issues.single.severity, EntityVaultIssueSeverity.error);
  });

  test('one corrupt file does not drop other good entries', () async {
    await writeEntity(id: 'pe_u_a0000001', title: 'A');
    await writeEntity(id: 'pe_u_b0000001', title: 'B');
    await writeEntity(id: 'pe_u_c0000001', title: 'C');
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_z_corrupt.md'),
    );
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_z_corrupt"\n'
      'title: [broken\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(detailed.entries.map((e) => e.entityId).toSet(), {
      'pe_u_a0000001',
      'pe_u_b0000001',
      'pe_u_c0000001',
    });
    expect(detailed.issues, hasLength(1));
    expect(detailed.issues.single.errorCode, 'yaml_parse_failed');
  });

  test('loadFromVault remains a List wrapper over entries', () async {
    await writeEntity(id: 'pe_u_wrap0001', title: 'Wrap');
    final list = await loader.loadFromVault(vault.path);
    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(list.map((e) => e.entityId), detailed.entries.map((e) => e.entityId));
    expect(list, isA<List>());
  });

  test('issues are ordered by relative path deterministically', () async {
    await File(p.join(vault.path, 'entities', 'person', 'z_last.md'))
        .create(recursive: true)
        .then(
          (f) => f.writeAsString(
            '---\nrecord_kind: ${RecordKind.entityJournal.name}\n'
            'entity_id: ""\ntitle: "Z"\n---\n\nbody\n',
            flush: true,
          ),
        );
    await File(p.join(vault.path, 'entities', 'person', 'a_first.md'))
        .create(recursive: true)
        .then(
          (f) => f.writeAsString(
            '---\nrecord_kind: ${RecordKind.freeformJournal.name}\n'
            'title: "A"\n---\n\nbody\n',
            flush: true,
          ),
        );
    await File(p.join(vault.path, 'entities', 'person', 'm_mid.md')).writeAsString(
      'no frontmatter\n',
      flush: true,
    );

    final detailed = await loader.loadFromVaultWithIssues(vault.path);
    expect(
      detailed.issues.map((i) => i.relativePath.replaceAll('\\', '/')).toList(),
      [
        'entities/person/a_first.md',
        'entities/person/m_mid.md',
        'entities/person/z_last.md',
      ],
    );
  });

  test('parseDetailed never embeds markdown body in issue diagnostics', () {
    const body = 'TOP_SECRET_ENTITY_BODY_CONTENT';
    final result = EntityJournalParser.parseDetailed(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_secret"\n'
      'title: [broken\n'
      '---\n\n'
      '$body\n',
      p.join('vault', 'entities', 'person', 'pe_u_secret.md'),
    );
    expect(result.entry, isNull);
    expect(result.issue, isNotNull);
    expect(result.issue!.toString(), isNot(contains(body)));
    expect(result.issue!.diagnostic ?? '', isNot(contains(body)));
  });

  test('repeated detailed loads do not auto-log issues', () async {
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_nolog.md'),
    );
    await bad.parent.create(recursive: true);
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_nolog"\n'
      'title: [broken\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final printed = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      printed.add(message ?? '');
    };
    try {
      final first = await loader.loadFromVaultWithIssues(vault.path);
      final second = await loader.loadFromVaultWithIssues(vault.path);
      expect(first.issues, hasLength(1));
      expect(second.issues, hasLength(1));
      expect(first.issues.single.errorCode, 'yaml_parse_failed');
      expect(
        printed.where((line) => line.contains('EntityVaultLoader')),
        isEmpty,
      );
    } finally {
      debugPrint = previous;
    }
  });

  test('repeated loadFromVault calls do not auto-log issues', () async {
    await writeEntity(id: 'pe_u_keep_log', title: 'Keep');
    final bad = File(
      p.join(vault.path, 'entities', 'person', 'pe_u_nolog2.md'),
    );
    await bad.writeAsString(
      '---\n'
      'record_kind: ${RecordKind.entityJournal.name}\n'
      'entity_id: "pe_u_nolog2"\n'
      'title: [broken\n'
      '---\n\n'
      'body\n',
      flush: true,
    );

    final printed = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      printed.add(message ?? '');
    };
    try {
      final first = await loader.loadFromVault(vault.path);
      final second = await loader.loadFromVault(vault.path);
      expect(first.map((e) => e.entityId), ['pe_u_keep_log']);
      expect(second.map((e) => e.entityId), ['pe_u_keep_log']);
      expect(
        printed.where((line) => line.contains('EntityVaultLoader')),
        isEmpty,
      );
    } finally {
      debugPrint = previous;
    }
  });
}
