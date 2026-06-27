import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/record_link_stale_label.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordLinkStaleLabel', () {
    test('isStaleExplicitLabel: label mismatch is stale', () {
      expect(
        RecordLinkStaleLabel.isStaleExplicitLabel(
          link: const RecordLink(
            sourceRecordId: '/works/a.md',
            kind: RecordLinkKind.explicitId,
            raw: 'pe_u_x',
            targetEntityId: 'pe_u_x',
            displayLabel: '나츠키 스바루',
          ),
          entityId: 'pe_u_x',
          currentTitle: '스바루',
        ),
        isTrue,
      );
    });

    test('isStaleExplicitLabel: matching label is not stale', () {
      expect(
        RecordLinkStaleLabel.isStaleExplicitLabel(
          link: const RecordLink(
            sourceRecordId: '/works/a.md',
            kind: RecordLinkKind.explicitId,
            raw: 'pe_u_x',
            targetEntityId: 'pe_u_x',
            displayLabel: '스바루',
          ),
          entityId: 'pe_u_x',
          currentTitle: '스바루',
        ),
        isFalse,
      );
    });

    test('isStaleExplicitLabel: no pipe label and titleOnly are not stale', () {
      expect(
        RecordLinkStaleLabel.isStaleExplicitLabel(
          link: const RecordLink(
            sourceRecordId: '/works/a.md',
            kind: RecordLinkKind.explicitId,
            raw: 'pe_u_x',
            targetEntityId: 'pe_u_x',
          ),
          entityId: 'pe_u_x',
          currentTitle: '스바루',
        ),
        isFalse,
      );
      expect(
        RecordLinkStaleLabel.isStaleExplicitLabel(
          link: const RecordLink(
            sourceRecordId: '/works/a.md',
            kind: RecordLinkKind.titleOnly,
            raw: '나츠키 스바루',
            targetTitle: '나츠키 스바루',
          ),
          entityId: 'pe_u_x',
          currentTitle: '스바루',
        ),
        isFalse,
      );
    });

    test('countForEntity uses incoming index without vault rewrite', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r2d_stale_');

      try {
        await service.setVaultPath(tempDir.path);

        const entityId = 'pe_u_natsuki1';
        const oldLabel = '나츠키 스바루';
        const newTitle = '스바루';

        final worksDir = Directory(p.join(tempDir.path, 'works'));
        await worksDir.create(recursive: true);

        final workPath = p.join(worksDir.path, 'memo.md');
        await File(workPath).writeAsString('''---
title: "Memo"
work_id: "wk_u_work0001"
---
[[$entityId|$newTitle]] 와 [[$entityId|$oldLabel]] 그리고 [[$entityId]]
''');

        await index.rebuildIndex();

        final stats = await RecordLinkStaleLabel.countForEntity(
          linkIndex: index,
          entityId: entityId,
          currentTitle: newTitle,
        );

        expect(stats.incomingRecordCount, 1);
        expect(stats.staleLinkCount, 1);
        expect(stats.staleRecordCount, 1);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
