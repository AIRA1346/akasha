import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../models/user_catalog_entity.dart';
import 'entity_journal_parser.dart';

/// `vault/entities/{type}/` 쓰기 — Wave 4.
class EntityVaultStore {
  const EntityVaultStore();

  static String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  Future<EntityJournalEntry> saveCatalogEntity({
    required String vaultPath,
    required UserCatalogEntity entity,
    required String body,
  }) async {
    if (vaultPath.isEmpty) {
      throw StateError('Vault path not set');
    }
    if (entity.isWorkEntity) {
      throw ArgumentError('work entities use VaultPort.saveItem');
    }

    final subdir = EntityJournalParser.entitySubdir(entity.anchorType);
    final dir = Directory(p.join(vaultPath, EntityJournalParser.entitiesDirName, subdir));
    await dir.create(recursive: true);

    final safeTitle = _makeSafeFilename(entity.title);
    final targetPath = p.join(dir.path, '$safeTitle.md');

    var addedAt = entity.addedAt;
    if (File(targetPath).existsSync()) {
      final existing = EntityJournalParser.parse(
        await File(targetPath).readAsString(),
        targetPath,
      );
      if (existing != null) addedAt = existing.addedAt;
    }

    final content = EntityJournalParser.serialize(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      body: body,
      addedAt: addedAt,
    );

    await _writeAtomic(targetPath, content);

    return EntityJournalEntry(
      entityType: entity.anchorType,
      entityId: entity.entityId,
      title: entity.title,
      body: body.trim(),
      addedAt: addedAt,
      storagePath: targetPath,
    );
  }

  Future<void> _writeAtomic(String targetPath, String content) async {
    final file = File(targetPath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final tempPath = p.join(
      parent.path,
      '.akasha_${DateTime.now().microsecondsSinceEpoch}_${p.basename(targetPath)}.tmp',
    );
    final temp = File(tempPath);
    try {
      await temp.writeAsString(content, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(targetPath);
    } catch (e) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
