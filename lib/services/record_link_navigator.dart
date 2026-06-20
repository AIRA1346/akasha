import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/record_link.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/user_catalog_entity.dart';
import '../screens/home/dialogs/entity_journal_dialog.dart';
import 'entity_vault_loader.dart';
import 'file_service.dart';

/// Wave 5 — wiki link tap · incoming record open.
abstract final class RecordLinkNavigator {
  static Future<void> navigateLink(
    BuildContext context, {
    required ParsedRecordLink link,
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
    required void Function(AkashaItem item) onOpenWork,
    RecordLinkPort? linkIndex,
  }) async {
    if (link.kind == RecordLinkKind.explicitId && link.targetEntityId != null) {
      await _openEntityId(
        context,
        entityId: link.targetEntityId!,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
        onOpenWork: onOpenWork,
        linkIndex: linkIndex,
      );
      return;
    }

    final title = link.targetTitle ?? link.raw;
    final resolved = resolveTitleToEntityId(
      title,
      userCatalog: userCatalog,
      vaultItems: vaultItems,
    );

    if (resolved != null) {
      await _openEntityId(
        context,
        entityId: resolved,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
        onOpenWork: onOpenWork,
        linkIndex: linkIndex,
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$title」 Entity를 아카이브에서 찾지 못했습니다.')),
    );
  }

  static Future<void> openRecordPath(
    BuildContext context, {
    required String storagePath,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort userCatalog,
    required void Function(AkashaItem item) onOpenWork,
  }) async {
    final item = await findVaultItemForRecordPath(
      storagePath: storagePath,
      vaultItems: vaultItems,
    );
    if (item != null) {
      onOpenWork(item);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('기록 열기: ${p.basename(p.normalize(storagePath))}')),
    );
  }

  /// incoming link path → vault work item (path · work_id · unique basename).
  static Future<AkashaItem?> findVaultItemForRecordPath({
    required String storagePath,
    required List<AkashaItem> vaultItems,
  }) async {
    final normalized = p.normalize(storagePath);

    for (final item in vaultItems) {
      final path = item.filePath;
      if (path != null && _pathsEqual(path, normalized)) {
        return item;
      }
    }

    final workId = await _readWorkIdFromMd(normalized);
    if (workId != null && workId.isNotEmpty) {
      for (final item in vaultItems) {
        if (item.workId == workId) return item;
      }
    }

    final base = p.basename(normalized).toLowerCase();
    AkashaItem? basenameMatch;
    var basenameCount = 0;
    for (final item in vaultItems) {
      final path = item.filePath;
      if (path == null || path.isEmpty) continue;
      if (p.basename(path).toLowerCase() != base) continue;
      basenameMatch = item;
      basenameCount++;
    }
    if (basenameCount == 1) return basenameMatch;

    return null;
  }

  static bool _pathsEqual(String a, String b) {
    final na = p.normalize(a);
    final nb = p.normalize(b);
    if (Platform.isWindows) {
      return na.toLowerCase() == nb.toLowerCase();
    }
    return na == nb;
  }

  static final RegExp _workIdPattern = RegExp(
    r'''work_id:\s*["']?([^"'\s]+)["']?''',
  );

  static Future<String?> _readWorkIdFromMd(String mdPath) async {
    try {
      final file = File(mdPath);
      if (!await file.exists()) return null;
      final lines = (await file.readAsString()).split('\n');
      if (lines.isEmpty || lines.first.trim() != '---') return null;

      for (var i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') break;
        final match = _workIdPattern.firstMatch(lines[i]);
        if (match != null) return match.group(1)?.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? resolveTitleToEntityId(
    String title, {
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
  }) {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return null;

    for (final entity in userCatalog.all) {
      if (entity.title.toLowerCase() == q) return entity.entityId;
      for (final alias in entity.aliases) {
        if (alias.toLowerCase() == q) return entity.entityId;
      }
    }

    for (final item in vaultItems) {
      if (item.title.toLowerCase() == q && item.workId.isNotEmpty) {
        return item.workId;
      }
    }

    return null;
  }

  static Future<void> _openEntityId(
    BuildContext context, {
    required String entityId,
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
    required void Function(AkashaItem item) onOpenWork,
    RecordLinkPort? linkIndex,
  }) async {
    final type = EntityIdCodec.typeFromId(entityId);

    if (type == EntityAnchorType.work || entityId.startsWith('sub_') || entityId.startsWith('gen_')) {
      for (final item in vaultItems) {
        if (item.workId == entityId) {
          onOpenWork(item);
          return;
        }
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('볼트에 work ($entityId) 아카이브가 없습니다.')),
      );
      return;
    }

    await userCatalog.load();
    UserCatalogEntity? catalog;
    for (final entity in userCatalog.all) {
      if (entity.entityId == entityId) {
        catalog = entity;
        break;
      }
    }

    if (catalog == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「$entityId」 Entity를 찾을 수 없습니다.')),
      );
      return;
    }

    final entry = await const EntityVaultLoader().findByEntityId(
      AkashaFileService().vaultPath,
      entityId,
    );
    if (!context.mounted) return;
    await showEntityJournalDialog(
      context,
      entity: catalog,
      entry: entry,
      linkIndex: linkIndex,
      userCatalog: userCatalog,
      vaultItems: vaultItems,
      onOpenWork: onOpenWork,
    );
  }
}
