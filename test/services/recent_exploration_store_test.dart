import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akasha/services/recent_exploration_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentExplorationStore', () {
    late RecentExplorationStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = RecentExplorationStore();
      await store.load();
    });

    test('records work with most recent first', () async {
      await store.recordWork('work-a');
      await store.recordWork('work-b');
      await store.recordWork('work-a');

      expect(store.itemKeys, [
        RecentExplorationStore.workKey('work-a'),
        RecentExplorationStore.workKey('work-b'),
      ]);
    });

    test('caps history at maxEntries', () async {
      for (var i = 0; i < RecentExplorationStore.maxEntries + 3; i++) {
        await store.recordWork('work-$i');
      }
      expect(store.itemKeys.length, RecentExplorationStore.maxEntries);
      expect(store.itemKeys.first, RecentExplorationStore.workKey('work-${RecentExplorationStore.maxEntries + 2}'));
    });
  });
}
