import '../../../core/archiving/record_link.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';

/// 워크벤치 connections 패널 — 링크된 work/entity 열기.
abstract final class WorkbenchLinkedRecordOps {
  static void openLinkedEntity({
    required UserCatalogEntity entity,
    void Function(UserCatalogEntity entity)? onRecordOpenEntity,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) {
    if (onRecordOpenEntity != null) {
      onRecordOpenEntity(entity);
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

  static void openLinkedWork({
    required AkashaItem work,
    void Function(AkashaItem item)? onRecordOpenWork,
    void Function(ParsedRecordLink link)? onWikiLinkTap,
  }) {
    if (onRecordOpenWork != null) {
      onRecordOpenWork(work);
      return;
    }
    onWikiLinkTap?.call(
      ParsedRecordLink(
        kind: RecordLinkKind.explicitId,
        raw: '[[${work.workId}]]',
        targetEntityId: work.workId,
      ),
    );
  }
}
