import 'package:flutter/material.dart';

import '../../../core/archiving/same_day_record_ref.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../core/archiving/record_link.dart';
import 'workbench_record_navigation.dart';

/// Workbench workspace — incoming·same-day 레코드 네비게이션.
abstract final class WorkbenchWorkspaceRecordNav {
  static Future<void> openIncoming({
    required BuildContext context,
    required String path,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort? userCatalog,
    required void Function(AkashaItem item)? onRecordOpenWork,
    required Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity,
    required void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) async {
    final catalog = userCatalog;
    if (catalog == null) return;

    await WorkbenchRecordNavigation.openIncoming(
      context: context,
      storagePath: path,
      vaultItems: vaultItems,
      userCatalog: catalog,
      onRecordOpenWork: onRecordOpenWork,
      onRecordOpenEntity: onRecordOpenEntity,
      onWikiLinkTap: onWikiLinkTap,
    );
  }

  static Future<void> openSameDay({
    required BuildContext context,
    required SameDayRecordRef ref,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort? userCatalog,
    required void Function(AkashaItem item)? onRecordOpenWork,
    required Future<void> Function(UserCatalogEntity entity)? onRecordOpenEntity,
    required void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) async {
    await WorkbenchRecordNavigation.openSameDay(
      context: context,
      ref: ref,
      vaultItems: vaultItems,
      userCatalog: userCatalog,
      onRecordOpenWork: onRecordOpenWork,
      onRecordOpenEntity: onRecordOpenEntity,
      onWikiLinkTap: onWikiLinkTap,
    );
  }
}
