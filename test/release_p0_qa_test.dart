import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/config/feature_flags.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 release QA (automated)', () {
    testWidgets('Q05 PosterCard has no keyboard shortcut for library menu',
        (tester) async {
      final item = createItem(
        workId: 'wk_p0_no_shortcut',
        title: 'No Shortcut Test',
        category: MediaCategory.manga,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosterCard(
              item: item,
              showPoster: false,
              onOpenLibraryMenu: (_) {},
            ),
          ),
        ),
      );

      final cardShortcuts = find.descendant(
        of: find.byType(PosterCard),
        matching: find.byType(Shortcuts),
      );
      expect(cardShortcuts, findsNothing);
    });

    test('Q11 recall card disabled for v1', () {
      expect(FeatureFlags.showRecallCard, isFalse);
    });

    test('Q09 saveItem notifies vault listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final vaultDir = await Directory.systemTemp.createTemp('akasha_p0_watch');
      final service = AkashaFileService();
      await service.setVaultPath('');

      var notifyCount = 0;
      final sub = service.onVaultUpdated.listen((_) => notifyCount++);
      await service.setVaultPath(vaultDir.path);
      final baseline = notifyCount;

      final item = createItem(
        workId: 'wk_p0_watch',
        title: 'Watch Test',
        category: MediaCategory.manga,
      );
      await service.saveItem(item);

      expect(notifyCount, greaterThan(baseline));
      expect(await service.loadAllItems(), hasLength(1));
      expect(File(item.filePath!).existsSync(), isTrue);

      await sub.cancel();
      await service.setVaultPath('');
      await vaultDir.delete(recursive: true);
    });

    test('Q09 external md edit triggers vault reload via poll', () async {
      SharedPreferences.setMockInitialValues({});
      final vaultDir = await Directory.systemTemp.createTemp('akasha_p0_ext');
      final mangaDir = Directory(p.join(vaultDir.path, 'manga'))
        ..createSync(recursive: true);
      final mdFile = File(p.join(mangaDir.path, 'external_edit.md'));

      final service = AkashaFileService();
      AkashaFileService.vaultPollInterval = const Duration(milliseconds: 50);
      addTearDown(() {
        AkashaFileService.vaultPollInterval = const Duration(seconds: 2);
      });

      await service.setVaultPath('');
      await service.setVaultPath(vaultDir.path);
      service.forceVaultPollFallback();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      var notifyCount = 0;
      final sub = service.onVaultUpdated.listen((_) => notifyCount++);

      await mdFile.writeAsString('---\ntitle: External\nwork_id: wk_ext\n---\n');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(notifyCount, greaterThan(0));
      expect(await service.loadAllItems(), hasLength(1));

      await sub.cancel();
      await service.setVaultPath('');
      await vaultDir.delete(recursive: true);
    });

    test('Q04 no showArchiveThenAddDialog call sites in lib', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        expect(
          text.contains('showArchiveThenAddDialog'),
          isFalse,
          reason: 'Found showArchiveThenAddDialog in ${entity.path}',
        );
        expect(
          text.contains('archive_then_add_dialog'),
          isFalse,
          reason: 'Found archive_then_add_dialog import in ${entity.path}',
        );
      }
    });
  });
}
