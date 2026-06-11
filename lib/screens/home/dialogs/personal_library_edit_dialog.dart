import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/personal_library_config.dart';
import '../../../services/works_registry.dart';
import '../../../utils/helpers.dart';

String _memberTitle(String workId, List<AkashaItem> vaultItems) {
  for (final item in vaultItems) {
    if (item.workId == workId ||
        WorksRegistry.resolveWorkId(item.workId) ==
            WorksRegistry.resolveWorkId(workId)) {
      return item.title;
    }
  }
  final work = WorksRegistry.getWorkById(workId);
  if (work != null) return work.displayTitle();
  return workId;
}

/// 나만의 서재 추가·설정 수정 (대시보드 설정과 동일한 필터 UI)
Future<PersonalLibraryConfig?> showPersonalLibraryEditDialog(
  BuildContext context, {
  PersonalLibraryConfig? config,
  List<AkashaItem> vaultItems = const [],
}) async {
  final isNew = config == null;
  final isMasterArchive =
      config?.id == PersonalLibraryConfig.masterArchiveId;
  final nameCtrl = TextEditingController(text: config?.name ?? '');
  AppDomain? tempDomain = config?.domain;
  final Set<MediaCategory> tempCategories =
      config != null ? Set.from(config.categories) : {};
  final Set<String> tempMyStatuses =
      config != null ? Set.from(config.myStatuses) : {};
  final Set<String> tempWorkStatuses =
      config != null ? Set.from(config.workStatuses) : {};
  var tempMemberOrder = config != null && config.isCurated
      ? List<String>.from(config.memberOrder)
      : <String>[];

  final result = await showDialog<PersonalLibraryConfig>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final Set<String> availableWorkOpts = {};
        final Set<String> availableMyOpts = {};
        for (final cat
            in tempCategories.isEmpty ? MediaCategory.values : tempCategories) {
          availableWorkOpts.addAll(workStatusOptionsFor(cat));
          availableMyOpts.addAll(myStatusOptionsFor(cat));
        }

        tempWorkStatuses.retainAll(availableWorkOpts);
        tempMyStatuses.retainAll(availableMyOpts);

        return AlertDialog(
          title: Text(isNew ? '➕ 나만의 서재 추가' : '⚙️ 나만의 서재 설정'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '서재 이름',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    readOnly: isMasterArchive,
                    decoration: InputDecoration(
                      hintText: '예: 인생 명작, 감상 완료 목록…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: isMasterArchive
                          ? 'master_archive 이름은 변경할 수 없습니다.'
                          : isNew
                              ? '새 서재는 작품을 담아 채웁니다. 필터는 설정에서 조정할 수 있습니다.'
                              : config!.isCurated
                                  ? '담긴 작품만 표시됩니다. 필터는 2차로 좁힙니다.'
                                  : '볼트에 아카이브된 작품만 필터로 표시됩니다.',
                      helperMaxLines: 2,
                    ),
                  ),
                  if (!isNew && config!.isCurated) ...[
                    const SizedBox(height: 16),
                    Text(
                      '담긴 작품 (${tempMemberOrder.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tempMemberOrder.isEmpty)
                      Text(
                        '아직 담긴 작품이 없습니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      )
                    else
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setD(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final id = tempMemberOrder.removeAt(oldIndex);
                            tempMemberOrder.insert(newIndex, id);
                          });
                        },
                        children: [
                          for (var i = 0; i < tempMemberOrder.length; i++)
                            ListTile(
                              key: ValueKey(tempMemberOrder[i]),
                              dense: true,
                              leading: const Icon(Icons.drag_handle, size: 18),
                              title: Text(
                                _memberTitle(tempMemberOrder[i], vaultItems),
                                style: const TextStyle(fontSize: 12),
                              ),
                              subtitle: Text(
                                tempMemberOrder[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => setD(() {
                                  tempMemberOrder.removeAt(i);
                                }),
                              ),
                            ),
                        ],
                      ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '대분류 (도메인) 필터',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<AppDomain?>(
                    initialValue: tempDomain,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('전체 도메인'),
                      ),
                      ...AppDomain.values.map(
                        (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                      ),
                    ],
                    onChanged: (v) => setD(() => tempDomain = v),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '소분류 (카테고리) 필터 (다중 선택 가능)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MediaCategory.values.map((cat) {
                      final isSelected = tempCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                        avatar: Icon(cat.icon, size: 12),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setD(() {
                            if (selected) {
                              tempCategories.add(cat);
                            } else {
                              tempCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '작품 상태 조건 필터 (다중 선택 가능)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: availableWorkOpts.map((status) {
                      final isSelected = tempWorkStatuses.contains(status);
                      return FilterChip(
                        label: Text(status, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setD(() {
                            if (selected) {
                              tempWorkStatuses.add(status);
                            } else {
                              tempWorkStatuses.remove(status);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '나의 상태 조건 필터 (다중 선택 가능)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: availableMyOpts.map((status) {
                      final isSelected = tempMyStatuses.contains(status);
                      return FilterChip(
                        label: Text(status, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setD(() {
                            if (selected) {
                              tempMyStatuses.add(status);
                            } else {
                              tempMyStatuses.remove(status);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                if (isNew) {
                  Navigator.pop(
                    ctx,
                    PersonalLibraryConfig(
                      id: 'personal_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      mode: PersonalLibraryMode.curated,
                      domain: tempDomain,
                      categories: tempCategories,
                      workStatuses: tempWorkStatuses,
                      myStatuses: tempMyStatuses,
                    ),
                  );
                } else {
                  config!.name = name;
                  config.domain = tempDomain;
                  config.categories = tempCategories;
                  config.workStatuses = tempWorkStatuses;
                  config.myStatuses = tempMyStatuses;
                  if (config.isCurated) {
                    config.memberOrder =
                        PersonalLibraryConfig.normalizeMemberOrder(
                      tempMemberOrder,
                    );
                  }
                  Navigator.pop(ctx, config);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    ),
  );

  nameCtrl.dispose();
  return result;
}
