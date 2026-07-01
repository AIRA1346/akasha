part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditTitleAndModeSection(
  BuildContext context,
  _CollectibleCollectionEditSession session,
  void Function(void Function()) setLocal,
) {
  final l10n = lookupAppL10n(context);
  return [
    TextField(
      controller: session.titleCtrl,
      autofocus: true,
      decoration: InputDecoration(
        labelText: l10n?.labelCollectionName ?? '컬렉션 이름',
        border: const OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<CollectibleCollectionMode>(
      initialValue: session.mode,
      decoration: InputDecoration(
        labelText: l10n?.labelMode ?? '모드',
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: CollectibleCollectionMode.filter,
          child: Text(l10n?.modeFilter ?? '필터 (태그·작품·kind)'),
        ),
        DropdownMenuItem(
          value: CollectibleCollectionMode.curated,
          child: Text(l10n?.modeCurated ?? '큐레이션 (직접 선택)'),
        ),
      ],
      onChanged: (v) {
        if (v != null) setLocal(() => session.mode = v);
      },
    ),
  ];
}
