import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/collectible_collection.dart';
import '../../../models/collectible_collection_filter.dart';
import '../../../models/collectible_collection_id_codec.dart';
import '../../../models/collectible_browse_item.dart';
import '../../../models/collectible_collection_preset.dart';
import '../../../models/collectible_kind.dart';
import '../../../models/collectible_ref.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/app_l10n.dart';

part 'collectible_collection_edit_dialog_picker_part.dart';
part 'collectible_collection_edit_dialog_session_part.dart';
part 'collectible_collection_edit_dialog_title_part.dart';
part 'collectible_collection_edit_dialog_preset_part.dart';
part 'collectible_collection_edit_dialog_filter_part.dart';
part 'collectible_collection_edit_dialog_curated_part.dart';
part 'collectible_collection_edit_dialog_actions_part.dart';
part 'collectible_collection_edit_dialog_delete_part.dart';

Future<CollectibleCollection?> showCollectibleCollectionEditDialog(
  BuildContext context, {
  CollectibleCollection? config,
  List<UserCatalogEntity> catalogEntities = const [],
  List<AkashaItem> vaultItems = const [],
}) async {
  final session = _CollectibleCollectionEditSession(
    config: config,
    catalogEntities: catalogEntities,
    vaultItems: vaultItems,
  );

  final l10n = lookupAppL10n(context);
  final result = await showDialog<CollectibleCollection>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(
          session.isNew
              ? (l10n?.collectionAddTitle ?? '컬렉션 추가')
              : (l10n?.collectionEditTitle ?? '컬렉션 설정'),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._collectibleCollectionEditTitleAndModeSection(
                  ctx,
                  session,
                  setLocal,
                ),
                if (session.isNew)
                  ..._collectibleCollectionEditPresetSection(ctx, session),
                if (session.mode == CollectibleCollectionMode.filter)
                  ..._collectibleCollectionEditFilterSection(
                    ctx,
                    session,
                    setLocal,
                  )
                else
                  ..._collectibleCollectionEditCuratedSection(
                    ctx,
                    session,
                    setLocal,
                  ),
              ],
            ),
          ),
        ),
        actions: _collectibleCollectionEditActions(ctx, session),
      ),
    ),
  );

  session.titleCtrl.dispose();
  return result;
}
