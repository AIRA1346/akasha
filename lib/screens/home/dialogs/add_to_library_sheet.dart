import 'package:flutter/material.dart';

import '../../../models/personal_library_config.dart';
import '../../../services/personal_library_membership_service.dart';

/// E1 — 여러 curated 서재에 동시 담기/제거 (Case D: IP 전체 옵션)
Future<void> showAddToLibrarySheet(
  BuildContext context, {
  required String displayTitle,
  required PersonalLibraryMembershipService membership,
  required List<String> workIds,
  String? activeLibraryId,
  Future<PersonalLibraryConfig?> Function()? onCreateLibrary,
  bool showIpScopeOption = false,
  List<String>? entireIpWorkIds,
}) async {
  if (workIds.isEmpty && onCreateLibrary == null) return;
  final ipIds = entireIpWorkIds ?? workIds;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        var useEntireIp = false;

        List<String> effectiveIds() =>
            showIpScopeOption && useEntireIp ? ipIds : workIds;

        final checked = <String, bool>{
          for (final lib in membership.curatedLibraries)
            lib.id: membership.librariesContainingAll(workIds).contains(lib.id),
        };

        void syncCheckedFromMembership() {
          final inLibs = membership.librariesContainingAll(effectiveIds());
          for (final lib in membership.curatedLibraries) {
            checked[lib.id] = inLibs.contains(lib.id);
          }
        }

        List<PersonalLibraryConfig> sortedLibs() {
          final list = List<PersonalLibraryConfig>.from(
            membership.curatedLibraries,
          )..sort((a, b) {
              if (activeLibraryId != null) {
                if (a.id == activeLibraryId) return -1;
                if (b.id == activeLibraryId) return 1;
              }
              return a.name.compareTo(b.name);
            });
          return list;
        }

        final sorted = sortedLibs();
        PersonalLibraryConfig? activeLib;
        if (activeLibraryId != null) {
          for (final lib in sorted) {
            if (lib.id == activeLibraryId) {
              activeLib = lib;
              break;
            }
          }
        }
        final ids = effectiveIds();
        final activeHasAll = activeLib != null &&
            ids.isNotEmpty &&
            ids.every((w) => membership.containsWork(activeLib!, w));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '서재에 담기 — $displayTitle',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showIpScopeOption) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(
                          workIds.length == 1 ? '이 매체만' : '선택 매체',
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('IP 전체 (${ipIds.length})'),
                      ),
                    ],
                    selected: {useEntireIp},
                    onSelectionChanged: (selected) {
                      setS(() {
                        useEntireIp = selected.first;
                        syncCheckedFromMembership();
                      });
                    },
                  ),
                ],
                if (activeLib != null && !activeHasAll) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await membership.addWorks(activeLib!.id, ids);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: Text('「${activeLib.name}」에 담기'),
                  ),
                ],
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'curated 서재가 없습니다. 아래에서 새로 만드세요.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final lib in sorted)
                          CheckboxListTile(
                            value: checked[lib.id] ?? false,
                            onChanged: (v) =>
                                setS(() => checked[lib.id] = v ?? false),
                            title: Text(lib.name),
                            subtitle: Text('${lib.memberOrder.length}작'),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                if (onCreateLibrary != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final created = await onCreateLibrary();
                        if (created == null) return;
                        setS(() {
                          checked[created.id] = true;
                        });
                      },
                      icon: const Icon(Icons.add_box_outlined, size: 18),
                      label: const Text('새 서재 만들기…'),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: sorted.isEmpty
                          ? null
                          : () async {
                              final targetIds = effectiveIds();
                              for (final lib in membership.curatedLibraries) {
                                final want = checked[lib.id] ?? false;
                                if (targetIds.isEmpty) continue;

                                if (want) {
                                  final missing = targetIds
                                      .where(
                                        (w) => !membership.containsWork(lib, w),
                                      )
                                      .toList();
                                  if (missing.isNotEmpty) {
                                    await membership.addWorks(lib.id, missing);
                                  }
                                } else {
                                  for (final w in targetIds) {
                                    if (membership.containsWork(lib, w)) {
                                      await membership.removeWork(lib.id, w);
                                    }
                                  }
                                }
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: const Text('적용'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
