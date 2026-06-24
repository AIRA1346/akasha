import 'dart:io';

import '../../../models/akasha_item.dart';
import '../../../services/markdown_parser.dart';

/// Work journal 디스크 reload.
abstract final class WorkDetailVaultReloadOps {
  static Future<AkashaItem?> loadWorkJournal({
    required String path,
    required String titleFallback,
  }) async {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final item = MarkdownParser.deserialize(content, titleFallback);
    item.filePath = path;
    return item;
  }
}
