part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditActions(
  BuildContext ctx,
  _CollectibleCollectionEditSession session,
) {
  final l10n = lookupAppL10n(ctx);

  return [
    TextButton(
      onPressed: () => Navigator.pop(ctx),
      child: Text(l10n?.actionCancel ?? '취소'),
    ),
    FilledButton(
      onPressed: () {
        final title = session.titleCtrl.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(l10n?.validationInputName ?? '이름을 입력해 주세요.')),
          );
          return;
        }
        if (session.mode == CollectibleCollectionMode.filter &&
            !CollectibleCollectionFilter.hasFilterPredicate(
              tagsAll: session.tags,
              relatedWorkId: session.relatedWorkId,
            )) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(l10n?.validationSpecifyTagOrWork ?? '태그 또는 작품을 하나 이상 지정해 주세요.'),
            ),
          );
          return;
        }
        if (session.isNew) {
          Navigator.pop(
            ctx,
            session.mode == CollectibleCollectionMode.filter
                ? CollectibleCollection(
                    id: CollectibleCollectionIdCodec.buildUserLocal(),
                    title: title,
                    mode: session.mode,
                    filter: session.buildFilter(),
                  )
                : CollectibleCollection(
                    id: CollectibleCollectionIdCodec.buildUserLocal(),
                    title: title,
                    mode: session.mode,
                    memberOrder: session.buildMemberOrder(),
                  ),
          );
          return;
        }
        final config = session.config!;
        config.title = title;
        config.mode = session.mode;
        if (session.mode == CollectibleCollectionMode.filter) {
          config.filter = session.buildFilter();
          config.memberOrder = const [];
        } else {
          config.filter = null;
          config.memberOrder = session.buildMemberOrder();
        }
        config.touch();
        Navigator.pop(ctx, config);
      },
      child: Text(
        session.isNew
            ? (l10n?.actionAdd ?? '추가')
            : (l10n?.actionSave ?? '저장'),
      ),
    ),
  ];
}
