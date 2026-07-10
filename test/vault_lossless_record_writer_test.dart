import 'dart:io';

import 'package:akasha/services/vault_lossless_record_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory vault;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_lossless_writer_');
  });

  tearDown(() async {
    if (await vault.exists()) {
      await vault.delete(recursive: true);
    }
  });

  test(
    'preserves unknown frontmatter through a recoverable record save',
    () async {
      final target = File(
        '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}entry.md',
      );
      await target.parent.create(recursive: true);
      const existing = '''---
record_id: "jr_example"
record_kind: freeformJournal
title: "before"
x_external:
  source: "future tool"
  values: [1, 2, 3]
---
before body
''';
      const proposed = '''---
record_id: "jr_example"
record_kind: freeformJournal
title: "after"
---
after body
''';
      await target.writeAsString(existing, flush: true);

      await VaultLosslessRecordWriter().write(
        vaultPath: vault.path,
        targetPath: target.path,
        proposedContent: proposed,
        existingContent: existing,
        reason: 'lossless_writer_test',
        ownedFrontmatterKeys: VaultFrontmatterOwnership.journal,
      );

      final saved = await target.readAsString();
      expect(saved, contains('title: "after"'));
      expect(
        saved,
        contains('x_external:\n  source: "future tool"\n  values: [1, 2, 3]'),
      );
      expect(saved, endsWith('after body\n'));
    },
  );

  test('quarantines proposed content when source YAML is malformed', () async {
    final target = File(
      '${vault.path}${Platform.pathSeparator}journal${Platform.pathSeparator}entry.md',
    );
    await target.parent.create(recursive: true);
    const malformed = '''---
title: [broken
x_external: keep
---
original body
''';
    const proposed = '''---
title: "after"
---
proposed body
''';
    await target.writeAsString(malformed, flush: true);

    await expectLater(
      VaultLosslessRecordWriter().write(
        vaultPath: vault.path,
        targetPath: target.path,
        proposedContent: proposed,
        existingContent: malformed,
        reason: 'malformed_yaml_test',
        ownedFrontmatterKeys: VaultFrontmatterOwnership.journal,
      ),
      throwsA(isA<VaultFrontmatterRejectedException>()),
    );

    expect(await target.readAsString(), malformed);
    final quarantineDir = Directory(
      '${vault.path}${Platform.pathSeparator}system${Platform.pathSeparator}recovery${Platform.pathSeparator}conflicts',
    );
    final files = await quarantineDir
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    expect(files, hasLength(1));
    expect(await files.single.readAsString(), proposed);
  });
}
