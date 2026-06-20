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

/// Work picker row — catalog Work entity or vault item fallback.
class CollectibleWorkPickerOption {
  final String workId;
  final String title;

  const CollectibleWorkPickerOption({
    required this.workId,
    required this.title,
  });
}

List<CollectibleWorkPickerOption> buildCollectibleWorkPickerOptions({
  required List<UserCatalogEntity> catalogEntities,
  List<AkashaItem> vaultItems = const [],
}) {
  final byId = <String, CollectibleWorkPickerOption>{};
  for (final entity in catalogEntities) {
    if (!entity.isWorkEntity || entity.entityId.isEmpty) continue;
    byId[entity.entityId] = CollectibleWorkPickerOption(
      workId: entity.entityId,
      title: entity.title,
    );
  }
  for (final item in vaultItems) {
    if (item.workId.isEmpty) continue;
    byId.putIfAbsent(
      item.workId,
      () => CollectibleWorkPickerOption(
        workId: item.workId,
        title: item.title,
      ),
    );
  }
  final options = byId.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  return options;
}

Future<CollectibleCollection?> showCollectibleCollectionEditDialog(
  BuildContext context, {
  CollectibleCollection? config,
  List<UserCatalogEntity> catalogEntities = const [],
  List<AkashaItem> vaultItems = const [],
}) async {
  final isNew = config == null;
  final titleCtrl = TextEditingController(text: config?.title ?? '');
  var mode = config?.mode ?? CollectibleCollectionMode.filter;
  var tags = List<String>.from(config?.filter?.tagsAll ?? const []);
  var relatedWorkId = config?.filter?.relatedWorkId;
  var kinds = List<CollectibleKind>.from(
    config?.filter?.kinds ?? const [CollectibleKind.person],
  );
  var selectedRefs = <CollectibleRef>{
    ...?config?.memberOrder,
  };
  final memberCount = config?.memberOrder.length ?? 0;
  final pickableEntities = catalogEntities
      .where((e) => !e.isWorkEntity && collectibleKindFromAnchor(e.anchorType) != null)
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  final pickableWorks = buildCollectibleWorkPickerOptions(
    catalogEntities: catalogEntities,
    vaultItems: vaultItems,
  );

  CollectibleCollectionFilter buildFilter() {
    return CollectibleCollectionFilter(
      kinds: kinds,
      tagsAll: tags.isEmpty ? null : tags,
      relatedWorkId: relatedWorkId,
    );
  }

  Set<String> knownWorkIds() =>
      pickableWorks.map((work) => work.workId).toSet();

  CollectibleWorkPickerOption? selectedWorkOption() {
    if (relatedWorkId == null) return null;
    for (final work in pickableWorks) {
      if (work.workId == relatedWorkId) return work;
    }
    return null;
  }

  final result = await showDialog<CollectibleCollection>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(isNew ? '컬렉션 추가' : '컬렉션 설정'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '컬렉션 이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CollectibleCollectionMode>(
                  value: mode,
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
                    if (v != null) setLocal(() => mode = v);
                  },
                ),
                if (isNew) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Cast 프리셋',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in CollectibleCollectionPresets.all)
                        FilledButton.tonal(
                          onPressed: preset.isAvailableIn(knownWorkIds())
                              ? () => Navigator.pop(ctx, preset.build())
                              : null,
                          child: Text(preset.title),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '볼트·카탈로그에 해당 Work가 있을 때만 활성화됩니다.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    '직접 만들기',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '태그 기반 · 작품 기반 · 혼합 — 아래에서 설정 후 「추가」',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
                if (mode == CollectibleCollectionMode.filter) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '태그 (tagsAll · exact match)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  EditableTagChips(
                    tags: tags,
                    onChanged: (next) => setLocal(() => tags = next),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '관련 작품 (relatedWorkId · Cast)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (pickableWorks.isEmpty)
                    Text(
                      '카탈로그·볼트에 Work가 없습니다.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      value: relatedWorkId != null &&
                              pickableWorks.any((w) => w.workId == relatedWorkId)
                          ? relatedWorkId
                          : null,
                      decoration: const InputDecoration(
                        labelText: '작품 선택',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('선택 안 함'),
                        ),
                        for (final work in pickableWorks)
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
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setLocal(() => relatedWorkId = value),
                    ),
                  if (isNew && selectedWorkOption() != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final work = selectedWorkOption()!;
                        final name = titleCtrl.text.trim();
                        final castTitle =
                            name.isEmpty ? '${work.title} Cast' : name;
                        Navigator.pop(
                          ctx,
                          buildRelatedWorkCollection(
                            title: castTitle,
                            workId: work.workId,
                          ),
                        );
                      },
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label: const Text('선택한 작품으로 Cast 만들기'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final kind in CollectibleKind.values)
                        if (kind != CollectibleKind.work)
                          FilterChip(
                          label: Text(kind.name),
                          selected: kinds.contains(kind),
                          onSelected: (selected) {
                            setLocal(() {
                              if (selected) {
                                kinds = [...kinds, kind];
                              } else {
                                kinds = kinds.where((k) => k != kind).toList();
                              }
                              if (kinds.isEmpty) {
                                kinds = [CollectibleKind.person];
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Work (작품)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (pickableWorks.isEmpty)
                    Text(
                      '카탈로그·볼트에 Work가 없습니다.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final work in pickableWorks)
                            CheckboxListTile(
                              dense: true,
                              title: Text(work.title),
                              subtitle: Text(
                                work.workId,
                                style: const TextStyle(fontSize: 10),
                              ),
                              value: selectedRefs.contains(
                                collectibleRefFromWorkId(work.workId),
                              ),
                              onChanged: (checked) {
                                setLocal(() {
                                  final ref =
                                      collectibleRefFromWorkId(work.workId);
                                  if (checked == true) {
                                    selectedRefs.add(ref);
                                  } else {
                                    selectedRefs.remove(ref);
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
                  if (pickableEntities.isEmpty)
                    Text(
                      '카탈로그에 Person·Concept 등 Entity가 없습니다.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final entity in pickableEntities)
                            CheckboxListTile(
                              dense: true,
                              title: Text(entity.title),
                              subtitle: Text(
                                entity.entityId,
                                style: const TextStyle(fontSize: 10),
                              ),
                              value: selectedRefs.contains(
                                collectibleRefFromEntity(entity),
                              ),
                              onChanged: (checked) {
                                setLocal(() {
                                  final ref = collectibleRefFromEntity(entity);
                                  if (checked == true) {
                                    selectedRefs.add(ref);
                                  } else {
                                    selectedRefs.remove(ref);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  if (memberCount > 0 || selectedRefs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '선택 ${selectedRefs.length}개 · 갤러리에서 순서 변경',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('이름을 입력해 주세요.')),
                );
                return;
              }
              if (mode == CollectibleCollectionMode.filter &&
                  !CollectibleCollectionFilter.hasFilterPredicate(
                    tagsAll: tags,
                    relatedWorkId: relatedWorkId,
                  )) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('태그 또는 작품을 하나 이상 지정해 주세요.'),
                  ),
                );
                return;
              }
              List<CollectibleRef> buildMemberOrder() {
                final ordered = <CollectibleRef>[];
                if (config != null && config.isCurated) {
                  for (final ref in config.memberOrder) {
                    if (selectedRefs.contains(ref)) {
                      ordered.add(ref);
                    }
                  }
                }
                for (final ref in selectedRefs) {
                  if (ordered.any(
                    (existing) => collectibleRefKey(existing) == collectibleRefKey(ref),
                  )) {
                    continue;
                  }
                  ordered.add(ref);
                }
                return ordered;
              }
              if (isNew) {
                Navigator.pop(
                  ctx,
                  mode == CollectibleCollectionMode.filter
                      ? CollectibleCollection(
                          id: CollectibleCollectionIdCodec.buildUserLocal(),
                          title: title,
                          mode: mode,
                          filter: buildFilter(),
                        )
                      : CollectibleCollection(
                          id: CollectibleCollectionIdCodec.buildUserLocal(),
                          title: title,
                          mode: mode,
                          memberOrder: buildMemberOrder(),
                        ),
                );
                return;
              }
              config!.title = title;
              config.mode = mode;
              if (mode == CollectibleCollectionMode.filter) {
                config.filter = buildFilter();
                config.memberOrder = const [];
              } else {
                config.filter = null;
                config.memberOrder = buildMemberOrder();
              }
              config.touch();
              Navigator.pop(ctx, config);
            },
            child: Text(isNew ? '추가' : '저장'),
          ),
        ],
      ),
    ),
  );

  titleCtrl.dispose();
  return result;
}

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
