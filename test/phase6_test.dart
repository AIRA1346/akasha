import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  setUpAll(() async {
    await WorksRegistry.init();
  });

  group('Phase 6 — Global Library Autoloading & Status Borders Tests', () {
    test('On-Demand Fusion merges local vault items with registry templates correctly', () {
      const eldenId = 'gen_game_appid1245620_2022';
      final userItems = <AkashaItem>[
        createItem(
          workId: eldenId,
          title: '엘든 링',
          category: MediaCategory.game,
          domain: AppDomain.generalCulture,
          myStatus: '클리어(완결)',
          workStatus: '출시됨',
        ),
      ];

      final userWorkIds = userItems.map((e) => e.workId).toSet();

      final filteredWorks = WorksRegistry.getFilteredWorksSync(
        domain: AppDomain.generalCulture,
        category: MediaCategory.game,
      );

      final List<AkashaItem> fusedList = [...userItems];
      for (final work in filteredWorks) {
        if (!WorksRegistry.setContainsWorkId(userWorkIds, work.workId)) {
          final defaultMyStatus = work.category.isContentType
              ? ContentMyStatus.notStarted.label
              : GameMyStatus.backlog.label;
          final defaultWorkStatus = work.category.isContentType
              ? ContentWorkStatus.completed.label
              : GameWorkStatus.released.label;

          fusedList.add(
            createItem(
              workId: work.workId,
              title: work.title,
              category: work.category,
              domain: work.domain,
              myStatus: defaultMyStatus,
              workStatus: defaultWorkStatus,
              creator: work.creator,
              releaseYear: work.releaseYear,
              rating: 0.0,
            ),
          );
        }
      }

      final fusedIds = fusedList.map((e) => e.workId).toList();
      expect(fusedIds, contains(eldenId));

      final minecraftId =
          WorksRegistry.getWorkById('gen_game_minecraft_2011')!.workId;
      final lolId =
          WorksRegistry.getWorkById('gen_game_league-of-legends_2009')!.workId;
      final axiomId = WorksRegistry.getWorkById('gen_game_axiom_2024')!.workId;
      expect(fusedIds, contains(minecraftId));
      expect(fusedIds, contains(lolId));
      expect(fusedIds, contains(axiomId));

      final elden = fusedList.firstWhere((e) => e.workId == eldenId);
      expect(elden.myStatusLabel, '클리어(완결)');

      final minecraft = fusedList.firstWhere((e) => e.workId == minecraftId);
      expect(minecraft.myStatusLabel, '볼 예정');
      expect(minecraft.rating, 0.0);
    });
  });
}
