import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_fusion_service.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/browse_section_filters.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/utils/status_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
    await FranchiseRegistry.init();
  });
  test('isWatchlistItem uses enum labels for content and game', () {
    final content = createItem(
      workId: 'sub_manga_test_2020',
      title: '테스트',
      category: MediaCategory.manga,
      myStatus: ContentMyStatus.notStarted.label,
      workStatus: ContentWorkStatus.completed.label,
    );
    final game = createItem(
      workId: 'gen_game_test_2020',
      title: '게임',
      category: MediaCategory.game,
      myStatus: GameMyStatus.backlog.label,
      workStatus: GameWorkStatus.released.label,
    );
    final finished = createItem(
      workId: 'sub_manga_done_2020',
      title: '완료',
      category: MediaCategory.manga,
      myStatus: ContentMyStatus.finished.label,
      workStatus: ContentWorkStatus.completed.label,
    );

    expect(isWatchlistItem(content), isTrue);
    expect(isWatchlistItem(game), isTrue);
    expect(isWatchlistItem(finished), isFalse);
    expect(isWatchlistStatusLabel('아직 안 봄'), isTrue);
  });

  test('isWatchlistBrowseCard includes franchise when any member is watchlist',
      () {
    final manga = createItem(
      workId: 'sub_manga_rezero_2014',
      title: 'Re:제로부터 시작하는 이세계 생활',
      category: MediaCategory.manga,
      myStatus: ContentMyStatus.finished.label,
      workStatus: ContentWorkStatus.completed.label,
    );
    final anime = createItem(
      workId: 'sub_animation_rezero-anime_2016',
      title: 'Re:제로',
      category: MediaCategory.animation,
      myStatus: ContentMyStatus.notStarted.label,
      workStatus: ContentWorkStatus.completed.label,
    );

    final cards = FranchiseFusionService.fuse(
      userFiltered: [manga, anime],
      registryWorks: const [],
      allUserItems: [manga, anime],
      selectedCategories: {},
    );
    final rezero = cards.firstWhere((c) => c.franchiseId == 'franchise_rezero');

    expect(isWatchlistItem(rezero.item), isFalse);
    expect(isWatchlistBrowseCard(rezero, [manga, anime]), isTrue);
    expect(filterWatchlistCards(cards, [manga, anime]), contains(rezero));
  });
}
