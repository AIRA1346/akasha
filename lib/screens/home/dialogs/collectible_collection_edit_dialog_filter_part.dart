part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditFilterSection(
  BuildContext ctx,
  _CollectibleCollectionEditSession session,
  void Function(void Function()) setLocal,
) {
  final l10n = lookupAppL10n(ctx);
  return [
    const SizedBox(height: 12),
    const Text(
      'Tags (tagsAll · exact match)',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 4),
    EditableTagChips(
      tags: session.tags,
      onChanged: (next) => setLocal(() => session.tags = next),
    ),
    const SizedBox(height: 12),
    const Text(
      'Related Work (relatedWorkId · Cast)',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 4),
    if (session.pickableWorks.isEmpty)
      Text(
        l10n?.noWorksInCatalogVault ?? '카탈로그·볼트에 Work가 없습니다.',
        style: TextStyle(color: AkashaColors.textMuted, fontSize: 12),
      )
    else
      DropdownButtonFormField<String?>(
        initialValue:
            session.relatedWorkId != null &&
                session.pickableWorks.any(
                  (w) => w.workId == session.relatedWorkId,
                )
            ? session.relatedWorkId
            : null,
        decoration: InputDecoration(
          labelText: l10n?.labelSelectWork ?? '작품 선택',
          border: const OutlineInputBorder(),
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(l10n?.optionNone ?? '선택 안 함'),
          ),
          for (final work in session.pickableWorks)
            DropdownMenuItem<String?>(
              value: work.workId,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(work.title),
                  Text(
                    work.workId,
                    style: TextStyle(
                      fontSize: 10,
                      color: AkashaColors.textCaption,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (value) => setLocal(() => session.relatedWorkId = value),
      ),
    if (session.isNew && session.selectedWorkOption() != null) ...[
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () {
          final work = session.selectedWorkOption()!;
          final name = session.titleCtrl.text.trim();
          final castTitle = name.isEmpty ? '${work.title} Cast' : name;
          Navigator.pop(
            ctx,
            buildRelatedWorkCollection(title: castTitle, workId: work.workId),
          );
        },
        icon: const Icon(Icons.groups_outlined, size: 18),
        label: Text(l10n?.createCastFromWork ?? '선택한 작품으로 Cast 만들기'),
      ),
    ],
    const SizedBox(height: 8),
    Wrap(
      spacing: 6,
      children: [
        for (final kind in CollectibleKind.values)
          if (kind != CollectibleKind.work)
            FilterChip(
              label: Text(kind.localizedLabel(l10n)),
              selected: session.kinds.contains(kind),
              onSelected: (selected) {
                setLocal(() {
                  if (selected) {
                    session.kinds = [...session.kinds, kind];
                  } else {
                    session.kinds = session.kinds
                        .where((k) => k != kind)
                        .toList();
                  }
                  if (session.kinds.isEmpty) {
                    session.kinds = [CollectibleKind.person];
                  }
                });
              },
            ),
      ],
    ),
  ];
}
