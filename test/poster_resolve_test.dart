import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/registry_models.dart';
import 'package:akasha/services/works_registry.dart';

void main() {
  group('WorksRegistry.resolvePosterPath', () {
    test('returns posterPath from search index without loaded shard', () {
      const workId = 'sub_animation_frieren_2023';
      const poster =
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx154587-qQTzQnEJJ3oB.jpg';

      final loader = WorksRegistry.loader;
      final originalIndex = List<RegistrySearchIndexEntry>.from(
        loader.searchIndex,
      );

      loader.searchIndex.clear();
      loader.searchIndex.add(
        const RegistrySearchIndexEntry(
          workId: workId,
          title: '장송의 프리렌',
          shardId: 'animation_F',
          category: MediaCategory.animation,
          domain: AppDomain.subculture,
          posterPath: poster,
        ),
      );

      addTearDown(() {
        loader.searchIndex
          ..clear()
          ..addAll(originalIndex);
      });

      expect(WorksRegistry.resolvePosterPath(workId), poster);
      expect(WorksRegistry.getWorkById(workId)?.posterPath, isNull);
    });
  });
}
