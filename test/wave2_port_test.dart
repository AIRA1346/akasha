import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/services/my_library_pipeline.dart';
import 'package:akasha/services/browse_pipeline.dart';
import 'package:akasha/services/works_registry.dart';
import 'fakes/fake_registry_port.dart';

void main() {
  group('Wave 2 Port-Adapter 격리 아키텍처 테스트', () {
    late FakeRegistryPort fakeRegistry;
    late BrowsePipeline browsePipeline;
    late MyLibraryPipeline myLibraryPipeline;

    setUp(() {
      fakeRegistry = FakeRegistryPort();
      browsePipeline = BrowsePipeline(fakeRegistry);
      myLibraryPipeline = MyLibraryPipeline(fakeRegistry);

      // 모의 사전 데이터 주입
      fakeRegistry.addWork(const RegistryWork(
        workId: 'wk_00000001',
        title: '슈타인즈 게이트',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
        creator: 'White Fox',
        releaseYear: 2011,
      ));
    });

    test('BrowsePipeline이 주입받은 FakeRegistryPort를 통해 사전 데이터를 올바르게 조회하고 필터링한다', () {
      final results = browsePipeline.build(
        allUserItems: [],
        filters: const BrowseFilterState(
          categories: {MediaCategory.animation},
        ),
      );

      expect(results.length, 1);
      expect(results.first.item.title, '슈타인즈 게이트');
      expect(results.first.item.workId, 'wk_00000001');
    });

    test('MyLibraryPipeline이 주입받은 FakeRegistryPort를 사용하여 정상적으로 동작한다', () {
      final userItems = [
        ContentItem(
          workId: 'wk_00000001',
          title: '슈타인즈 게이트',
          category: MediaCategory.animation,
          domain: AppDomain.subculture,
        )..filePath = '/vault/animation/steins-gate.md',
      ];

      // Curated 서재 정의
      final library = PersonalLibraryConfig(
        id: 'lib_001',
        name: '내 최애작',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_00000001'],
      );

      final results = myLibraryPipeline.build(
        userItems,
        library: library,
        filters: const BrowseFilterState(),
      );

      expect(results.length, 1);
      expect(results.first.item.title, '슈타인즈 게이트');
    });
  });
}
