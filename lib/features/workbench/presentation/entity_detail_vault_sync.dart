import 'dart:io';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../services/entity_journal_parser.dart';

/// Entity journal 디스크 reload — WorkbenchVaultDiskSync와 함께 사용.
abstract final class EntityDetailVaultSync {
  static Future<EntityJournalEntry?> loadJournalFromDisk(String path) async {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return EntityJournalParser.parse(content, path);
  }
}
