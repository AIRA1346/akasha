part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditTitleAndModeSection(
  _CollectibleCollectionEditSession session,
  void Function(void Function()) setLocal,
) {
  return [
    TextField(
      controller: session.titleCtrl,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: '컬렉션 이름',
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<CollectibleCollectionMode>(
      initialValue: session.mode,
      decoration: const InputDecoration(
        labelText: '모드',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: CollectibleCollectionMode.filter,
          child: Text('필터 (태그·작품·kind)'),
        ),
        DropdownMenuItem(
          value: CollectibleCollectionMode.curated,
          child: Text('큐레이션 (직접 선택)'),
        ),
      ],
      onChanged: (v) {
        if (v != null) setLocal(() => session.mode = v);
      },
    ),
  ];
}
