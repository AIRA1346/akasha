part of 'collectible_collection_edit_dialog.dart';

Future<bool?> showDeleteCollectibleCollectionConfirmDialog(
  BuildContext context,
) {
  final l10n = lookupAppL10n(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.deleteCollectionTitle ?? '컬렉션 삭제'),
      content: Text(
        l10n?.deleteCollectionConfirm ?? '이 컬렉션을 삭제할까요? Entity 데이터는 유지됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n?.actionCancel ?? '취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n?.actionDelete ?? '삭제'),
        ),
      ],
    ),
  );
}
