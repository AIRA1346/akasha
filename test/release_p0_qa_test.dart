import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/config/feature_flags.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/poster_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 release QA (automated)', () {
    testWidgets('Q05 PosterCard registers Shift+F10 library menu shortcut',
        (tester) async {
      final item = createItem(
        workId: 'wk_p0_shift_f10',
        title: 'Shift F10 Test',
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
      expect(cardShortcuts, findsOneWidget);
      final shortcutsWidget = tester.widget<Shortcuts>(cardShortcuts);
      final hasShiftF10 = shortcutsWidget.shortcuts.keys.any(
        (activator) =>
            activator is SingleActivator &&
            activator.trigger == LogicalKeyboardKey.f10 &&
            activator.shift == true,
      );
      expect(hasShiftF10, isTrue);
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
