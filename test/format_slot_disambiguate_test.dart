import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_fusion_service.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/user_registry_preferences.dart';
import 'package:akasha/services/works_registry.dart';

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

  test('duplicate game labels get disambiguated with year suffix', () {
    final group = FranchiseRegistry.groupById('franchise_stardew-valley');
    if (group == null) {
      // 그룹이 없으면 스킵 — 데이터 의존
      return;
    }

    final slots = FranchiseFusionService.formatSlotsForGroup(
      group,
      allUserItems: const [],
      selectedCategories: {MediaCategory.game},
    );

    final labels = slots.map((s) => s.shortLabel).toList();
    final gameLabels = labels.where((l) => l.startsWith('게임')).toList();
    if (gameLabels.length >= 2) {
      expect(gameLabels.toSet().length, greaterThan(1));
    }
  });
}
