import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/models/enums.dart';

void main() {
  group('PersonalLibraryConfig', () {
    test('defaultLibraries includes seven presets', () {
      final libs = PersonalLibraryConfig.defaultLibraries();
      expect(libs, hasLength(7));
      expect(
        libs.map((l) => l.id).toSet(),
        PersonalLibraryConfig.presetIds,
      );
    });

    test('archive_book uses book category', () {
      final book = PersonalLibraryConfig.defaultLibraries().firstWhere(
        (l) => l.id == 'archive_book',
      );
      expect(book.name, '내 책·라노벨 아카이브');
      expect(book.categories, {MediaCategory.book});
      expect(book.isPreset, isTrue);
    });

    test('json round-trip', () {
      final original = PersonalLibraryConfig(
        id: 'personal_1',
        name: '커스텀 서재',
      );
      final restored = PersonalLibraryConfig.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.inclusionRules, ['archived']);
    });
  });
}
