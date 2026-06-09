import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/registry_catalog_filter.dart';

void main() {
  group('isMaintainerCatalogProbe', () {
    test('detects scale-exp work id', () {
      const work = RegistryWork(
        workId: 'sub_webtoon_scale-exp-b7-probe-eta_2026',
        title: 'probe',
        category: MediaCategory.webtoon,
        domain: AppDomain.subculture,
        tags: ['scale', 'expansion'],
      );
      expect(isMaintainerCatalogProbe(work), isTrue);
    });

    test('ignores normal catalog work', () {
      const work = RegistryWork(
        workId: 'wk_000000409',
        title: 'Solo Leveling',
        category: MediaCategory.webtoon,
        domain: AppDomain.subculture,
      );
      expect(isMaintainerCatalogProbe(work), isFalse);
    });
  });
}
