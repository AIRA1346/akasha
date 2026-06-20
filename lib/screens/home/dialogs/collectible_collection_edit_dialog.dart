import 'package:flutter/material.dart';

import '../../../models/collectible_collection.dart';
import '../../../models/collectible_collection_filter.dart';
import '../../../models/collectible_collection_id_codec.dart';
import '../../../models/collectible_kind.dart';
import '../../../models/collectible_ref.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../widgets/editable_tag_chips.dart';

Future<CollectibleCollection?> showCollectibleCollectionEditDialog(
  BuildContext context, {
  CollectibleCollection? config,
  List<UserCatalogEntity> catalogEntities = const [],
}) async {
  final isNew = config == null;
  final titleCtrl = TextEditingController(text: config?.title ?? '');
  var mode = config?.mode ?? CollectibleCollectionMode.filter;
  var tags = List<String>.from(config?.filter?.tagsAll ?? const []);
  var kinds = List<CollectibleKind>.from(
    config?.filter?.kinds ?? const [CollectibleKind.person],
  );
  var selectedMemberIds = config?.memberOrder.map((r) => r.id).toSet() ?? <String>{};
  final memberCount = config?.memberOrder.length ?? 0;
  final pickableEntities = catalogEntities
      .where((e) => !e.isWorkEntity && collectibleKindFromAnchor(e.anchorType) != null)
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

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
                      child: Text('필터 (태그·kind)'),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final kind in CollectibleKind.values)
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
                              value: selectedMemberIds.contains(entity.entityId),
                              onChanged: (checked) {
                                setLocal(() {
                                  if (checked == true) {
                                    selectedMemberIds.add(entity.entityId);
                                  } else {
                                    selectedMemberIds.remove(entity.entityId);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  if (memberCount > 0 || selectedMemberIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '선택 ${selectedMemberIds.length}명 · 갤러리에서 순서 변경',
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
              if (mode == CollectibleCollectionMode.filter && tags.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('태그를 하나 이상 입력해 주세요.')),
                );
                return;
              }
              List<CollectibleRef> buildMemberOrder() {
                final byId = {
                  for (final e in pickableEntities) e.entityId: e,
                };
                final ordered = <CollectibleRef>[];
                if (config != null && config.isCurated) {
                  for (final ref in config.memberOrder) {
                    if (selectedMemberIds.contains(ref.id)) {
                      ordered.add(ref);
                    }
                  }
                }
                for (final id in selectedMemberIds) {
                  if (ordered.any((r) => r.id == id)) continue;
                  final entity = byId[id];
                  if (entity == null) continue;
                  ordered.add(collectibleRefFromEntity(entity));
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
                          filter: CollectibleCollectionFilter(
                            kinds: kinds,
                            tagsAll: tags,
                          ),
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
                config.filter = CollectibleCollectionFilter(
                  kinds: kinds,
                  tagsAll: tags,
                );
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

CollectibleRef collectibleRefFromEntity(UserCatalogEntity entity) {
  final kind = collectibleKindFromAnchor(entity.anchorType);
  return CollectibleRef(
    kind: kind ?? CollectibleKind.person,
    id: entity.entityId,
  );
}
