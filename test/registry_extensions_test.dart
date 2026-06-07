import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/registry_extension_labels.dart';

void main() {
  test('RegistryWork parses extensions and formats game labels', () {
    final work = RegistryWork.fromJson({
      'workId': 'gen_game_minecraft_2011',
      'title': '마인크래프트',
      'category': 'game',
      'domain': 'generalCulture',
      'extensions': {
        'platforms': ['PC', '콘솔'],
        'steamAppId': '322170',
      },
    });

    expect(work.extensions['steamAppId'], '322170');
    final lines = formatRegistryExtensionLines(work);
    expect(lines, contains('플랫폼: PC · 콘솔'));
    expect(lines, contains('Steam App ID: 322170'));
  });

  test('minecraft shard includes extensions after catalog load', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await WorksRegistry.init();
    await WorksRegistry.prefetchForFilters(
      categories: {MediaCategory.game},
    );

    final work = WorksRegistry.getWorkById('gen_game_minecraft_2011');
    expect(work, isNotNull);
    expect(work!.extensions['platforms'], isA<List>());
  });
}
