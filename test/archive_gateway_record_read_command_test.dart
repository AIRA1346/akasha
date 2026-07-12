import 'dart:convert';
import 'dart:io';

import 'package:akasha/services/akasha_command_runner.dart';
import 'package:akasha/services/archive_gateway_record_read_command.dart';
import 'package:akasha/services/archive_index_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vault;
  late ArchiveGatewayRecordReadCommand command;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_gateway_read_');
    final source = File(
      p.join(vault.path, 'works', 'movie', 'wk_u_read001.md'),
    );
    await source.parent.create(recursive: true);
    await source.writeAsString(_sourceMarkdown, flush: true);
    await ArchiveIndexManager().rebuildAll(vaultPath: vault.path);
    command = ArchiveGatewayRecordReadCommand();
  });

  tearDown(() async {
    if (await vault.exists()) await vault.delete(recursive: true);
  });

  test('looks up a title without exposing a physical Vault path', () async {
    final result = await command.lookup(
      vaultPath: vault.path,
      payload: {'name': 'CAA', 'limit': 5},
    );

    expect(result.ok, isTrue);
    final matches = result.toJson()['matches'] as List;
    expect(matches, hasLength(1));
    final match = matches.single as Map;
    expect(match['recordId'], 'rec_wk_u_read001');
    expect(match['targetId'], 'wk_u_read001');
    expect(match.containsKey('path'), isFalse);
  });

  test(
    'reads one exact Markdown record with the revision of returned bytes',
    () async {
      final result = await command.read(
        vaultPath: vault.path,
        payload: {'recordId': 'rec_wk_u_read001', 'maxBytes': 4096},
      );

      expect(result.ok, isTrue);
      final record = result.toJson()['record'] as Map;
      expect(record['recordId'], 'rec_wk_u_read001');
      expect(record['targetId'], 'wk_u_read001');
      expect(record['revision'], startsWith('v2:sha256:'));
      expect(record['markdown'], _sourceMarkdown);
      expect(record.containsKey('path'), isFalse);
    },
  );

  test('refuses silent truncation and unsupported request fields', () async {
    final tooLarge = await command.read(
      vaultPath: vault.path,
      payload: {'recordId': 'rec_wk_u_read001', 'maxBytes': 10},
    );
    final unsupported = await command.read(
      vaultPath: vault.path,
      payload: {'recordId': 'rec_wk_u_read001', 'unexpected': true},
    );

    expect(tooLarge.ok, isFalse);
    expect((tooLarge.toJson()['error'] as Map)['code'], 'record_too_large');
    expect(unsupported.ok, isFalse);
    expect(
      (unsupported.toJson()['error'] as Map)['code'],
      'command_payload_invalid',
    );
  });

  test(
    'routes a JSON-file request through the desktop command vocabulary',
    () async {
      final runner = AkashaCommandRunner(recordReadCommand: command);

      final outcome = await runner.execute(
        args: ['record', 'read', '--vault', vault.path],
        stdinText: jsonEncode({
          'recordId': 'rec_wk_u_read001',
          'maxBytes': 4096,
        }),
      );

      expect(outcome.exitCode, 0);
      expect(outcome.response['ok'], isTrue);
      expect(
        (outcome.response['record'] as Map)['recordId'],
        'rec_wk_u_read001',
      );
    },
  );

  test('refuses a title match without a physical record id', () async {
    final legacy = File(p.join(vault.path, 'Legacy source.md'));
    await legacy.writeAsString('''
---
work_id: "wk_u_legacy001"
entity_type: work
title: "Legacy Source"
category: movie
---

No physical record id yet.
''');
    await ArchiveIndexManager().rebuildAll(vaultPath: vault.path);

    final result = await command.lookup(
      vaultPath: vault.path,
      payload: {'name': 'Legacy Source'},
    );

    expect(result.ok, isFalse);
    expect((result.toJson()['error'] as Map)['code'], 'record_id_required');
  });
}

const _sourceMarkdown = '''---
record_id: "rec_wk_u_read001"
work_id: "wk_u_read001"
entity_type: work
title: "Cyber Action Archive"
aliases: ["CAA"]
category: movie
---

The source explicitly names a person.
''';
