import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/personal_library_config.dart';
import '../../../utils/helpers.dart';

/// 나만의 서재 추가·설정 수정 (대시보드 설정과 동일한 필터 UI)
Future<PersonalLibraryConfig?> showPersonalLibraryEditDialog(
  BuildContext context, {
  PersonalLibraryConfig? config,
}) async {
  final isNew = config == null;
  final isPreset = config?.isPreset ?? false;
  final nameCtrl = TextEditingController(text: config?.name ?? '');
  AppDomain? tempDomain = config?.domain;
  final Set<MediaCategory> tempCategories =
      config != null ? Set.from(config.categories) : {};
  final Set<String> tempMyStatuses =
      config != null ? Set.from(config.myStatuses) : {};
  final Set<String> tempWorkStatuses =
      config != null ? Set.from(config.workStatuses) : {};

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
                    readOnly: isPreset,
                    decoration: InputDecoration(
                      hintText: '예: 인생 명작, 감상 완료 목록…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: isPreset
                          ? '기본 서재 이름은 변경할 수 없습니다. 필터만 수정됩니다.'
                          : '볼트에 아카이브된 작품만 표시됩니다.',
                      helperMaxLines: 2,
                    ),
                  ),
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
