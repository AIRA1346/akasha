import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/franchise_representative_picker.dart';
import 'package:akasha/services/user_registry_preferences.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
    await FranchiseRegistry.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserRegistryPreferences.instance.load();
  });

  test('dedupeLocalByFranchise collapses franchise siblings to one row', () {
    final manga = createItem(
      workId: 'sub_manga_86-eighty-six_2017',
      title: '86 -에이티식스-',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.finished.label,
      workStatus: ContentWorkStatus.completed.label,
      rating: 5.0,
    );
    final novel = createItem(
      workId: 'sub_book_86-light-novel_2016',
      title: '86 -에이티식스-',
      category: MediaCategory.book,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.notStarted.label,
      workStatus: ContentWorkStatus.completed.label,
      rating: 0.0,
    );

    final deduped =
        FranchiseRepresentativePicker.dedupeLocalByFranchise([manga, novel]);
    expect(deduped, hasLength(1));
    expect(
      FranchiseRegistry.groupFor(deduped.first.workId)?.id,
      'franchise_86',
    );
  });

  test('pickBest prefers primary workId when none archived', () {
    final group = FranchiseRegistry.groupById('franchise_rezero');
    expect(group, isNotNull);

    final manga = createItem(
      workId: 'sub_manga_rezero_2014',
      title: 'Re:제로부터 시작하는 이세계 생활',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.notStarted.label,
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

    final picked = FranchiseRepresentativePicker.pickBest(
      [anime, manga],
      group!,
    );
    expect(picked.workId, manga.workId);
  });
}
