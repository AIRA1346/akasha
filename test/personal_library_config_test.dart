import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/models/enums.dart';

void main() {
  group('PersonalLibraryConfig', () {
    test('defaultLibraries is master_archive only', () {
      final libs = PersonalLibraryConfig.defaultLibraries();
      expect(libs, hasLength(1));
      expect(libs.first.id, PersonalLibraryConfig.masterArchiveId);
      expect(libs.first.name, 'master_archive');
      expect(libs.first.isMasterArchive, isTrue);
    });

    test('normalizeLibraries removes legacy presets and keeps custom', () {
      final normalized = PersonalLibraryConfig.normalizeLibraries([
        PersonalLibraryConfig(
          id: 'archive_manga',
          name: '내 만화 아카이브',
          categories: {MediaCategory.manga},
        ),
        PersonalLibraryConfig(
          id: 'archive_all',
          name: '내 전체 아카이브',
          workStatuses: {'완결'},
        ),
        PersonalLibraryConfig(
          id: 'personal_1',
          name: '커스텀 서재',
          categories: {MediaCategory.game},
        ),
      ]);

      expect(normalized, hasLength(2));
      expect(normalized.first.id, PersonalLibraryConfig.masterArchiveId);
      expect(normalized.first.workStatuses, {'완결'});
      expect(normalized[1].id, 'personal_1');
    });

    test('migrateActiveId maps legacy preset to master_archive', () {
      final libs = PersonalLibraryConfig.defaultLibraries();
      expect(
        PersonalLibraryConfig.migrateActiveId('archive_manga', libs),
        PersonalLibraryConfig.masterArchiveId,
      );
      expect(
        PersonalLibraryConfig.migrateActiveId('personal_1', [
          ...libs,
          PersonalLibraryConfig(id: 'personal_1', name: '커스텀'),
        ]),
        'personal_1',
      );
    });

    test('json round-trip with filters', () {
      final original = PersonalLibraryConfig(
        id: 'personal_1',
        name: '커스텀 서재',
        domain: AppDomain.subculture,
        categories: {MediaCategory.manga, MediaCategory.animation},
        workStatuses: {'완결'},
        myStatuses: {'전부 봄'},
      );
      final restored = PersonalLibraryConfig.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.domain, AppDomain.subculture);
      expect(restored.categories, original.categories);
      expect(restored.workStatuses, original.workStatuses);
      expect(restored.myStatuses, original.myStatuses);
      expect(restored.inclusionRules, ['archived']);
      expect(restored.mode, PersonalLibraryMode.filter);
      expect(restored.memberOrder, isEmpty);
    });

    test('memberOrder is SSOT and dedupes', () {
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_a', 'wk_b', 'wk_a'],
      );
      expect(lib.memberOrder, ['wk_a', 'wk_b']);
      expect(lib.memberWorkIds, {'wk_a', 'wk_b'});
    });

    test('fromJson migrates legacy memberWorkIds to memberOrder', () {
      final restored = PersonalLibraryConfig.fromJson({
        'id': 'lib',
        'name': '레거시',
        'memberWorkIds': ['wk_1', 'wk_2'],
      });
      expect(restored.memberOrder, ['wk_1', 'wk_2']);
      expect(restored.mode, PersonalLibraryMode.filter);
    });

    test('new curated config defaults to curated mode', () {
      final lib = PersonalLibraryConfig(
        id: 'personal_new',
        name: '인생 명작',
        mode: PersonalLibraryMode.curated,
      );
      expect(lib.isCurated, isTrue);
      expect(lib.isFilterMode, isFalse);
    });
  });
}
