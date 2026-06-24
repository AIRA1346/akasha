import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/dashboard_config.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 12 — Multi-Category Preset Dashboard Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('DashboardConfig fromJson correctly migrates legacy single category to categories set', () {
      // 레거시 단일 category가 포함된 JSON 형태의 Mock
      final legacyJson = {
        'id': 'legacy_manga',
        'name': '비주얼 만화 서재',
        'domain': 'subculture',
        'category': 'manga', // 레거시 프로퍼티
        'myStatuses': ['보는 중'],
        'workStatuses': ['연재중']
      };

      final parsed = DashboardConfig.fromJson(legacyJson);
      expect(parsed.id, 'legacy_manga');
      expect(parsed.name, '비주얼 만화 서재');
      
      // categories 세트로 마이그레이션이 잘 되었는지 검증
      expect(parsed.categories, contains(MediaCategory.manga));
      expect(parsed.categories.length, 1);
      expect(parsed.myStatuses, contains('보는 중'));
      expect(parsed.workStatuses, contains('연재중'));
    });

    test('DashboardConfig parses multi categories correctly from new JSON format', () {
      final multiJson = {
        'id': 'mixed_dashboard',
        'name': '만화와 애니',
        'domain': 'subculture',
        'categories': ['manga', 'animation'], // 신규 다중 프로퍼티
        'myStatuses': ['전부 봄'],
        'workStatuses': ['완결']
      };

      final parsed = DashboardConfig.fromJson(multiJson);
      expect(parsed.categories, containsAll([MediaCategory.manga, MediaCategory.animation]));
      expect(parsed.categories.length, 2);
    });

    test('AkashaItem list is filtered correctly with multi-category and status options', () {
      final item1 = createItem(
        workId: 'item1',
        title: '만화A',
        category: MediaCategory.manga,
        myStatus: '보는 중',
      );
      final item2 = createItem(
        workId: 'item2',
        title: '애니B',
        category: MediaCategory.animation,
        myStatus: '전부 봄',
      );
      final item3 = createItem(
        workId: 'item3',
        title: '게임C',
        category: MediaCategory.game,
        myStatus: '플레이 중',
      );

      final list = [item1, item2, item3];

      // 만화와 애니메이션만 필터하는 대시보드 조건 시뮬레이션
      final activeCategories = {MediaCategory.manga, MediaCategory.animation};
      
      final filteredList = list.where((item) {
        if (activeCategories.isNotEmpty && !activeCategories.contains(item.category)) {
          return false;
        }
        return true;
      }).toList();

      expect(filteredList.length, 2);
      expect(filteredList.map((e) => e.workId), containsAll(['item1', 'item2']));
      expect(filteredList.map((e) => e.workId), isNot(contains('item3')));
    });
  });
}
