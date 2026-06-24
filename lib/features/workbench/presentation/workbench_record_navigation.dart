import 'package:flutter/material.dart';

import '../../../core/archiving/record_link.dart';
import '../../../core/archiving/record_kind.dart';
import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/record_link_navigator.dart';

/// Incoming·sameDay 레코드 열기 (Work·Entity 워크벤치 공통).
abstract final class WorkbenchRecordNavigation {
  static String formatWhen(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  static Future<void> openIncoming({
    required BuildContext context,
    required String storagePath,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort userCatalog,
    void Function(AkashaItem item)? onRecordOpenWork,
    Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) =>
      RecordLinkNavigator.openRecordPath(
        context,
        storagePath: storagePath,
        vaultItems: vaultItems,
        userCatalog: userCatalog,
        onOpenWork: (item) => _openWork(
          item: item,
          onRecordOpenWork: onRecordOpenWork,
          onWikiLinkTap: onWikiLinkTap,
        ),
        onOpenEntity: (entity) => _openEntity(
          entity: entity,
          onRecordOpenEntity: onRecordOpenEntity,
          onWikiLinkTap: onWikiLinkTap,
        ),
      );

  static Future<void> openSameDay({
    required BuildContext context,
    required SameDayRecordRef ref,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort? userCatalog,
    void Function(AkashaItem item)? onRecordOpenWork,
    Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) async {
    if (ref.kind == RecordKind.workJournal && userCatalog != null) {
      await openIncoming(
        context: context,
        storagePath: ref.storagePath,
        vaultItems: vaultItems,
        userCatalog: userCatalog,
        onRecordOpenWork: onRecordOpenWork,
        onRecordOpenEntity: onRecordOpenEntity,
        onWikiLinkTap: onWikiLinkTap,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${ref.kindLabel} · ${ref.title}'),
        content: Text(
          '${formatWhen(ref.when.toLocal())}\n${ref.storagePath}',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  static void _openWork({
    required AkashaItem item,
    void Function(AkashaItem item)? onRecordOpenWork,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) {
    if (onRecordOpenWork != null) {
      onRecordOpenWork(item);
      return;
    }
    onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${item.workId}]]',
        targetEntityId: item.workId,
      ),
    );
  }

  static Future<void> _openEntity({
    required UserCatalogEntity entity,
    Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) async {
    if (onRecordOpenEntity != null) {
      await onRecordOpenEntity(entity);
      return;
    }
    onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${entity.entityId}]]',
        targetEntityId: entity.entityId,
      ),
    );
  }
}
