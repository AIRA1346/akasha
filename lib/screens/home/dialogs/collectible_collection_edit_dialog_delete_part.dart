part of 'collectible_collection_edit_dialog.dart';

Future<bool?> showDeleteCollectibleCollectionConfirmDialog(
  BuildContext context,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('컬렉션 삭제'),
      content: const Text('이 컬렉션을 삭제할까요? Entity 데이터는 유지됩니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
