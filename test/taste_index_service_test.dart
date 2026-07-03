import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/taste_signal.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/taste_index_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;
  late TasteIndexService service;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_taste_index_');
    service = TasteIndexService();
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test(
    'rebuild derives evidence-backed taste signals from vault markdown',
    () async {
      final work = createItem(
        workId: 'wk_u_taste001',
        title: 'Signal Movie',
        category: MediaCategory.movie,
        myStatus: 'finished',
        rating: 4.5,
        tags: ['Action OST', 'Night Drive'],
        memorableQuotes: ['The sound makes the chase feel alive.'],
        review: 'I keep returning to the soundtrack during action scenes.',
        isHallOfFame: true,
      );
      work.bodyRaw =
          '${MarkdownParser.serialize(work).split('---').skip(2).join('---')}\n'
          'Related: [[co_u_music001|favorite soundtrack]]';

      final file = File(
        p.join(vaultDir.path, 'works', 'movie', 'wk_u_taste001.md'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(MarkdownParser.serialize(work), flush: true);

      final index = await service.rebuildFromVault(vaultDir.path);

      expect(
        await File(
          p.join(
            vaultDir.path,
            '.akasha',
            'indexes',
            TasteIndexService.indexFileName,
          ),
        ).exists(),
        isTrue,
      );
      expect(
        index.signals.map((signal) => signal.signalType),
        containsAll([
          TasteSignalType.rating,
          TasteSignalType.status,
          TasteSignalType.favorite,
          TasteSignalType.tag,
          TasteSignalType.memo,
          TasteSignalType.quote,
          TasteSignalType.link,
        ]),
      );
      expect(
        index.signals.every(
          (signal) =>
              signal.sourceRecordId == 'rec_wk_u_taste001' &&
              signal.evidencePath == 'works/movie/wk_u_taste001.md' &&
              signal.evidenceField.isNotEmpty &&
              signal.weight >= 0 &&
              signal.weight <= 1,
        ),
        isTrue,
      );

      final tagSignals = await service.queryByTarget(
        vaultDir.path,
        'tag:action-ost',
      );
      expect(tagSignals, hasLength(1));
      expect(tagSignals.single.value, 'Action OST');

      final linkSignals = await service.queryByTarget(
        vaultDir.path,
        'co_u_music001',
      );
      expect(linkSignals, hasLength(1));
      expect(linkSignals.single.evidenceField, 'body.links[0]');
    },
  );

  test('rebuild replaces stale signals and preserves load contract', () async {
    final file = File(
      p.join(vaultDir.path, 'works', 'book', 'wk_u_rebuild01.md'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      MarkdownParser.serialize(
        createItem(
          workId: 'wk_u_rebuild01',
          title: 'First Taste',
          category: MediaCategory.book,
          rating: 5,
          tags: ['Warm'],
        ),
      ),
      flush: true,
    );

    final first = await service.rebuildFromVault(vaultDir.path);
    expect(first.signalsForTarget('tag:warm'), hasLength(1));

    await file.writeAsString(
      MarkdownParser.serialize(
        createItem(
          workId: 'wk_u_rebuild01',
          title: 'First Taste',
          category: MediaCategory.book,
          rating: 3,
          tags: ['Cold'],
        ),
      ),
      flush: true,
    );

    await service.rebuildFromVault(vaultDir.path);
    final loaded = await service.load(vaultDir.path);

    expect(loaded.signalsForTarget('tag:warm'), isEmpty);
    expect(loaded.signalsForTarget('tag:cold'), hasLength(1));

    final raw =
        jsonDecode(
              await File(
                p.join(
                  vaultDir.path,
                  '.akasha',
                  'indexes',
                  TasteIndexService.indexFileName,
                ),
              ).readAsString(),
            )
            as Map<String, dynamic>;
    expect(raw['targetIndex'], contains('tag:cold'));
    expect(raw['sourceIndex'], contains('rec_wk_u_rebuild01'));
  });
}
