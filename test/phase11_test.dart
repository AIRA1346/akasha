import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/dashboard_config.dart';
import 'package:akasha/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 11 — Custom Dashboard & Sidebar Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('DashboardConfig serialization and deserialization works correctly', () {
      final config = DashboardConfig(
        id: 'test_id',
        name: 'manga_dashboard',
        categories: {MediaCategory.manga},
        myStatuses: {'보는 중', '전부 봄'},
        workStatuses: {'연재중'},
      );

      final jsonMap = config.toJson();
      expect(jsonMap['id'], 'test_id');
      expect(jsonMap['name'], 'manga_dashboard');
      expect(jsonMap.containsKey('domain'), isFalse);
      expect(jsonMap['categories'], contains('manga'));
      expect(jsonMap['myStatuses'], containsAll(['보는 중', '전부 봄']));
      expect(jsonMap['workStatuses'], containsAll(['연재중']));

      final parsed = DashboardConfig.fromJson(jsonMap);
      expect(parsed.id, 'test_id');
      expect(parsed.name, 'manga_dashboard');
      expect(parsed.categories, contains(MediaCategory.manga));
      expect(parsed.myStatuses, containsAll(['보는 중', '전부 봄']));
      expect(parsed.workStatuses, containsAll(['연재중']));
    });

    test('DashboardConfig ignores legacy domain in JSON', () {
      final parsed = DashboardConfig.fromJson({
        'id': 'master_index',
        'name': '전체보기',
        'domain': 'subculture',
        'categories': [],
      });

      expect(parsed.id, 'master_index');
      expect(parsed.name, '전체보기');
      expect(parsed.categories, isEmpty);
    });

    test('SharedPreferences saves and loads DashboardConfigs list correctly', () async {
      final list = [
        DashboardConfig(id: '1', name: 'Manga Only', categories: {MediaCategory.manga}),
        DashboardConfig(id: '2', name: 'Game Only', categories: {MediaCategory.game}),
      ];

      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString('akasha_dashboards', encoded);

      final loadedStr = prefs.getString('akasha_dashboards');
      expect(loadedStr, isNotNull);

      final decoded = jsonDecode(loadedStr!) as List;
      final loaded = decoded
          .map((e) => DashboardConfig.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(loaded, hasLength(2));
      expect(loaded[0].categories, contains(MediaCategory.manga));
      expect(loaded[1].categories, contains(MediaCategory.game));
    });
  });
}
