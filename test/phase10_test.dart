import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 10 — Section Sort & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sortItems orders items by titleAsc, ratingDesc, recentlyAdded, and yearDesc correctly', () {
      final item1 = createItem(
        workId: 'a',
        title: '가',
        category: MediaCategory.game,
        rating: 3.5,
        releaseYear: 2020,
      )..addedAt = DateTime(2026, 1, 1);

      final item2 = createItem(
        workId: 'b',
        title: '다',
        category: MediaCategory.game,
        rating: 4.5,
        releaseYear: 2018,
      )..addedAt = DateTime(2026, 1, 3);

      final item3 = createItem(
        workId: 'c',
        title: '나',
        category: MediaCategory.game,
        rating: 4.0,
        releaseYear: 2022,
      )..addedAt = DateTime(2026, 1, 2);

      final list = [item1, item2, item3];

      // titleAsc 검증
      final sortedTitle = sortItems(list, SortCriteria.titleAsc);
      expect(sortedTitle[0].title, '가');
      expect(sortedTitle[1].title, '나');
      expect(sortedTitle[2].title, '다');

      // ratingDesc 검증
      final sortedRating = sortItems(list, SortCriteria.ratingDesc);
      expect(sortedRating[0].rating, 4.5);
      expect(sortedRating[1].rating, 4.0);
      expect(sortedRating[2].rating, 3.5);

      // recentlyAdded 검증 (addedAt 내림차순)
      final sortedAdded = sortItems(list, SortCriteria.recentlyAdded);
      expect(sortedAdded[0].workId, 'b'); // 1월 3일
      expect(sortedAdded[1].workId, 'c'); // 1월 2일
      expect(sortedAdded[2].workId, 'a'); // 1월 1일

      // yearDesc 검증
      final sortedYear = sortItems(list, SortCriteria.yearDesc);
      expect(sortedYear[0].releaseYear, 2022);
      expect(sortedYear[1].releaseYear, 2020);
      expect(sortedYear[2].releaseYear, 2018);
    });

    test('SharedPreferences reads and writes sort criteria correctly', () async {
      SharedPreferences.setMockInitialValues({
        'akasha_sort_hof': 'ratingDesc',
        'akasha_sort_library': 'yearDesc',
        'akasha_sort_yearly': 'recentlyAdded',
        'akasha_sort_watchlist': 'titleAsc',
      });

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('akasha_sort_hof'), 'ratingDesc');
      expect(prefs.getString('akasha_sort_library'), 'yearDesc');
      expect(prefs.getString('akasha_sort_yearly'), 'recentlyAdded');
      expect(prefs.getString('akasha_sort_watchlist'), 'titleAsc');

      // 값 쓰기 테스트
      await prefs.setString('akasha_sort_hof', SortCriteria.titleAsc.name);
      expect(prefs.getString('akasha_sort_hof'), 'titleAsc');
    });

    test('SharedPreferences reads and writes section expanded states correctly', () async {
      SharedPreferences.setMockInitialValues({
        'akasha_expanded_hof': false,
        'akasha_expanded_library': true,
        'akasha_expanded_yearly': false,
        'akasha_expanded_watchlist': true,
      });

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('akasha_expanded_hof'), false);
      expect(prefs.getBool('akasha_expanded_library'), true);
      expect(prefs.getBool('akasha_expanded_yearly'), false);
      expect(prefs.getBool('akasha_expanded_watchlist'), true);

      // 값 쓰기 테스트
      await prefs.setBool('akasha_expanded_hof', true);
      expect(prefs.getBool('akasha_expanded_hof'), true);
    });
  });
}
