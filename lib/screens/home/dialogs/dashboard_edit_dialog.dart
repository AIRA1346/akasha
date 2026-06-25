import 'package:flutter/material.dart';

import '../../../models/dashboard_config.dart';
import '../../../models/enums.dart';
import '../../../utils/helpers.dart';
import '../../../theme/akasha_colors.dart';

/// 대시보드 추가·수정 다이얼로그
Future<void> showDashboardEditDialog(
  BuildContext context, {
  required DashboardConfig? config,
  required void Function(DashboardConfig dashboard, bool isNew) onSaved,
}) async {
  final isNew = config == null;
  final nameCtrl = TextEditingController(text: config?.name ?? '');
  final Set<MediaCategory> tempCategories =
      config != null ? Set.from(config.categories) : {};
  final Set<String> tempMyStatuses =
      config != null ? Set.from(config.myStatuses) : {};
  final Set<String> tempWorkStatuses =
      config != null ? Set.from(config.workStatuses) : {};

  await showDialog(
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
          title: Text(isNew ? '➕ 새 대시보드 추가' : '⚙️ 대시보드 설정 수정'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '대시보드 이름',
                    style: TextStyle(
                      fontSize: 11,
                      color: AkashaColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'manga_dashboard 등 입력...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '소분류 (카테고리) 필터 (다중 선택 가능)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AkashaColors.textMuted,
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
                      color: AkashaColors.textMuted,
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
                      color: AkashaColors.textMuted,
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
                  onSaved(
                    DashboardConfig(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      categories: tempCategories,
                      myStatuses: tempMyStatuses,
                      workStatuses: tempWorkStatuses,
                    ),
                    true,
                  );
                } else {
                  config.name = name;
                  config.categories = tempCategories;
                  config.myStatuses = tempMyStatuses;
                  config.workStatuses = tempWorkStatuses;
                  onSaved(config, false);
                }
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    ),
  );
}
