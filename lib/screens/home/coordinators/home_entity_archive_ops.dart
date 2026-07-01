import 'package:flutter/material.dart';
import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/browse_entity_scope.dart';
import '../../../models/user_catalog_entity.dart';
import '../dialogs/add_catalog_entity_dialog.dart';
import '../home_browse_filter_controller.dart';
import '../../../utils/app_l10n.dart';

/// Entity 아카이브·등록 후 필터·스낵 피드백.
abstract final class HomeEntityArchiveOps {
  static void onEntityArchived({
    required BuildContext context,
    required UserCatalogEntity entity,
    required EntityJournalEntry? entry,
    required HomeBrowseFilterController filterCtrl,
    required void Function() rebuild,
    required bool Function() isMounted,
    required void Function(String message) showSnack,
  }) {
    filterCtrl.setEntityScope(browseScopeForEntityType(entity.anchorType));
    filterCtrl.highlightCatalogEntity(entity.entityId);
    rebuild();

    final l10n = lookupAppL10n(context);
    final badge = entityTypeBadgeLabel(entity.anchorType);
    if (entry != null) {
      showSnack(
        l10n != null
            ? l10n.successEntityArchived(badge, entity.title)
            : '$badge 「${entity.title}」 아카이브에 추가됨 · 기록 → Entity에서 확인',
      );
    } else {
      showSnack(
        l10n != null
            ? l10n.successEntityRegisteredOnly(badge, entity.title)
            : '$badge 「${entity.title}」 이름만 등록됨 · Fusion에서 아카이브 가능',
      );
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (!isMounted()) return;
      filterCtrl.clearEntityHighlight();
      rebuild();
    });
  }
}
