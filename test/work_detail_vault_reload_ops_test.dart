import 'dart:io';

import 'package:akasha/features/workbench/presentation/work_detail_vault_reload_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadWorkJournal deserializes vault markdown', () async {
    final dir = await Directory.systemTemp.createTemp('work_vault_reload');
    addTearDown(() => dir.delete(recursive: true));

    final item = createItem(
      workId: 'wk_manga_test',
      title: '테스트',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );
    final path = '${dir.path}/test.md';
    await File(path).writeAsString(MarkdownParser.serialize(item));

    final reloaded = await WorkDetailVaultReloadOps.loadWorkJournal(
      path: path,
      titleFallback: 'fallback',
    );

    expect(reloaded, isNotNull);
    expect(reloaded!.title, '테스트');
    expect(reloaded.filePath, path);
  });
}
