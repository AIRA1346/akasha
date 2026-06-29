part of 'collectible_collection_edit_dialog.dart';

List<Widget> _collectibleCollectionEditCuratedSection(
  _CollectibleCollectionEditSession session,
  void Function(void Function()) setLocal,
) {
  return [
    const SizedBox(height: 12),
    const Text(
      'Work (작품)',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 4),
    if (session.pickableWorks.isEmpty)
      Text(
        '카탈로그·볼트에 Work가 없습니다.',
        style: TextStyle(color: AkashaColors.textMuted, fontSize: 12),
      )
    else
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final work in session.pickableWorks)
              CheckboxListTile(
                dense: true,
                title: Text(work.title),
                subtitle: Text(
                  work.workId,
                  style: const TextStyle(fontSize: 10),
                ),
                value: session.selectedRefs.contains(
                  collectibleRefFromWorkId(work.workId),
                ),
                onChanged: (checked) {
                  setLocal(() {
                    final ref = collectibleRefFromWorkId(work.workId);
                    if (checked == true) {
                      session.selectedRefs.add(ref);
                    } else {
                      session.selectedRefs.remove(ref);
                    }
                  });
                },
              ),
          ],
        ),
      ),
    const SizedBox(height: 12),
    const Text(
      'Entity (Person · Concept · …)',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 4),
    if (session.pickableEntities.isEmpty)
      Text(
        '카탈로그에 Person·Concept 등 Entity가 없습니다.',
        style: TextStyle(color: AkashaColors.textMuted, fontSize: 12),
      )
    else
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entity in session.pickableEntities)
              CheckboxListTile(
                dense: true,
                title: Text(entity.title),
                subtitle: Text(
                  entity.entityId,
                  style: const TextStyle(fontSize: 10),
                ),
                value: session.selectedRefs.contains(
                  collectibleRefFromEntity(entity),
                ),
                onChanged: (checked) {
                  setLocal(() {
                    final ref = collectibleRefFromEntity(entity);
                    if (checked == true) {
                      session.selectedRefs.add(ref);
                    } else {
                      session.selectedRefs.remove(ref);
                    }
                  });
                },
              ),
          ],
        ),
      ),
    if (session.memberCount > 0 || session.selectedRefs.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '선택 ${session.selectedRefs.length}개 · 갤러리에서 순서 변경',
          style: TextStyle(color: AkashaColors.textMuted, fontSize: 12),
        ),
      ),
  ];
}
