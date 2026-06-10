import 'dart:io';

import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/detail/detail_archive_setup.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('needsSetup is true for registry-only virtual item', () async {
    final service = AkashaFileService();
    await service.setVaultPath('');

    final item = createItem(
      workId: 'wk_test_virtual',
      title: '가상 작품',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );

    expect(DetailArchiveSetup.needsSetup(item), isTrue);
  });

  test('needsSetup is true for auto-archived stub with empty user fields',
      () async {
    final service = AkashaFileService();
    final tempDir = await Directory.systemTemp.createTemp('akasha_setup_test_');
    try {
      await service.setVaultPath(tempDir.path);

      final item = createItem(
        workId: 'wk_test_stub',
        title: '자동 아카이브',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      )..filePath = '${tempDir.path}/manga/test.md';

      expect(DetailArchiveSetup.needsSetup(item), isTrue);
    } finally {
      await service.setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('needsSetup is false when poster or rating is set', () async {
    final service = AkashaFileService();
    final tempDir = await Directory.systemTemp.createTemp('akasha_setup_test_');
    try {
      await service.setVaultPath(tempDir.path);

      final item = createItem(
        workId: 'wk_test_done',
        title: '완성 아카이브',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        rating: 4.5,
        posterPath: 'https://example.com/poster.jpg',
      )..filePath = '${tempDir.path}/manga/done.md';

      expect(DetailArchiveSetup.needsSetup(item), isFalse);
    } finally {
      await service.setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
