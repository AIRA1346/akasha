import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/browse_pipeline.dart';
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

  test('build fuses rezero siblings and applies myStatus filter', () {
    final manga = createItem(
      workId: 'sub_manga_rezero_2014',
      title: 'Re:제로부터 시작하는 이세계 생활',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.finished.label,
      workStatus: ContentWorkStatus.completed.label,
    );
    final anime = createItem(
      workId: 'sub_animation_rezero-anime_2016',
      title: 'Re:제로',
      category: MediaCategory.animation,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.notStarted.label,
      workStatus: ContentWorkStatus.completed.label,
    );

    final allCards = BrowsePipeline.build(
      allUserItems: [manga, anime],
      filters: const BrowseFilterState(),
    );
    final rezero =
        allCards.where((c) => c.franchiseId == 'franchise_rezero').toList();
    expect(rezero, hasLength(1));

    final watchlistOnly = BrowsePipeline.build(
      allUserItems: [anime],
      filters: BrowseFilterState(
        myStatuses: {ContentMyStatus.notStarted.label},
      ),
    );
    expect(
      watchlistOnly.where((c) => c.franchiseId == 'franchise_rezero'),
      hasLength(1),
    );
    expect(rezero.first.formatSlots, hasLength(3));
  });
}
