import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_fusion_service.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/user_registry_preferences.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
    await FranchiseRegistry.init();
    await WorksRegistry.prefetchMasterCatalog();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserRegistryPreferences.instance.load();
  });

  group('FranchiseFusionService', () {
    test('emits one card with all format slots for franchise 86', () {
      final cards = FranchiseFusionService.fuse(
        userFiltered: const [],
        registryWorks: WorksRegistry.getFilteredWorksSync(
          domain: AppDomain.subculture,
          category: null,
        ),
        allUserItems: const [],
        selectedCategories: {},
      );

      final eightySix = cards.where((c) => c.franchiseId == 'franchise_86');
      expect(eightySix, hasLength(1));
      expect(eightySix.first.formatSlots, hasLength(2));
      expect(
        eightySix.first.formatSlots.map((s) => s.shortLabel).toList(),
        containsAll(['만화', '라노벨']),
      );
    });

    test('user manga 86 produces one card with tracked manga chip', () {
      final userItem = createItem(
        workId: 'sub_manga_86-eighty-six_2017',
        title: '86 -에이티식스-',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        myStatus: '보는 중',
        workStatus: '완결',
        rating: 5.0,
      );

      final cards = FranchiseFusionService.fuse(
        userFiltered: [userItem],
        registryWorks: const [],
        allUserItems: [userItem],
        selectedCategories: {},
      );

      expect(cards, hasLength(1));
      expect(cards.first.franchiseId, 'franchise_86');
      final mangaSlot = cards.first.formatSlots.firstWhere(
        (s) => s.shortLabel == '만화',
      );
      expect(mangaSlot.state.name, 'tracked');
    });

    test('rezero manga + anime + light novel fuse to one card with unified title',
        () {
      final manga = createItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로부터 시작하는 이세계 생활',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        myStatus: ContentMyStatus.notStarted.label,
        workStatus: ContentWorkStatus.completed.label,
        rating: 0.0,
      );
      final novel = createItem(
        workId: 'sub_book_rezero-light-novel_2014',
        title: 'Re:제로 라이트노벨',
        category: MediaCategory.book,
        domain: AppDomain.subculture,
        myStatus: ContentMyStatus.notStarted.label,
        workStatus: ContentWorkStatus.completed.label,
        rating: 0.0,
      );
      final anime = createItem(
        workId: 'sub_animation_rezero-anime_2016',
        title: 'Re:제로',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
        myStatus: ContentMyStatus.notStarted.label,
        workStatus: ContentWorkStatus.completed.label,
        rating: 0.0,
      );

      final cards = FranchiseFusionService.fuse(
        userFiltered: [manga, novel, anime],
        registryWorks: const [],
        allUserItems: [manga, novel, anime],
        selectedCategories: {},
      );

      final rezero = cards.where((c) => c.franchiseId == 'franchise_rezero');
      expect(rezero, hasLength(1));
      expect(rezero.first.item.title, 'Re:제로부터 시작하는 이세계 생활');
      expect(rezero.first.formatSlots, hasLength(3));
    });
  });
}
