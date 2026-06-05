import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  group('Phase 6 — Global Library Autoloading & Status Borders Tests', () {
    test('On-Demand Fusion merges local vault items with registry templates correctly', () {
      // 1. 임의의 실제 사용자 아카이브 작품 (1종)
      final userItems = <AkashaItem>[
        createItem(
          workId: 'eldenring_2022',
          title: '엘든 링',
          category: MediaCategory.game,
          domain: AppDomain.generalCulture,
          myStatus: '클리어(완결)',
          workStatus: '출시됨',
        ),
      ];

      final userWorkIds = userItems.map((e) => e.workId).toSet();

      // 2. game 카테고리와 generalCulture 도메인을 기준으로 사전(Registry)에서 필터링 조회
      // ( works_registry.dart에 등록된 젤다, 스타듀밸리, 마인크래프트, 롤, 엘든링 등이 걸러짐)
      final filteredWorks = WorksRegistry.getFilteredWorks(
        domain: AppDomain.generalCulture,
        category: MediaCategory.game,
      );

      // 3. 융합 (Join) 실행
      final List<AkashaItem> fusedList = [...userItems];
      for (final work in filteredWorks) {
        if (!userWorkIds.contains(work.workId)) {
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

      // 검증:
      // - 융합된 리스트에는 'eldenring_2022' (실제) 와 사전에서 땡겨온 'minecraft_2011', 'lol_2009', 'zelda_botw_2017' 등이 모두 들어가 있어야 함.
      final fusedIds = fusedList.map((e) => e.workId).toList();
      expect(fusedIds, contains('eldenring_2022'));
      expect(fusedIds, contains('minecraft_2011'));
      expect(fusedIds, contains('lol_2009'));
      expect(fusedIds, contains('axiom_game'));

      // - 실제 등록된 엘든링은 '클리어(완결)' 상태를 유지해야 함.
      final elden = fusedList.firstWhere((e) => e.workId == 'eldenring_2022');
      expect(elden.myStatusLabel, '클리어(완결)');

      // - 사전에서 가상으로 융합된 마인크래프트는 기본 '볼 예정' 및 별점 0.0이어야 함.
      final minecraft = fusedList.firstWhere((e) => e.workId == 'minecraft_2011');
      expect(minecraft.myStatusLabel, '볼 예정');
      expect(minecraft.rating, 0.0);
    });
  });
}
