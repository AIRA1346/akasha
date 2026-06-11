import 'package:flutter/material.dart';

import '../../../models/personal_library_config.dart';
import '../../../services/personal_library_membership_service.dart';

/// E1 — 여러 curated 서재에 동시 담기/제거
Future<void> showAddToLibrarySheet(
  BuildContext context, {
  required String workId,
  required String displayTitle,
  required PersonalLibraryMembershipService membership,
  String? activeLibraryId,
  Future<PersonalLibraryConfig?> Function()? onCreateLibrary,
}) async {
  var curated = membership.curatedLibraries;
  if (curated.isEmpty && onCreateLibrary == null) return;

  final initiallyIn = membership.librariesContaining(workId);
  final checked = <String, bool>{
    for (final lib in curated) lib.id: initiallyIn.contains(lib.id),
  };

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
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
        final activeContains =
            activeLib != null && (checked[activeLib.id] ?? false);

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
                if (activeLib != null && !activeContains) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await membership.addWork(activeLib!.id, workId);
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
                              final add = <String>{};
                              final remove = <String>{};
                              for (final lib in membership.curatedLibraries) {
                                final want = checked[lib.id] ?? false;
                                final had = initiallyIn.contains(lib.id);
                                if (want && !had) add.add(lib.id);
                                if (!want && had) remove.add(lib.id);
                              }
                              await membership.applyMembershipChanges(
                                workId: workId,
                                addToLibraryIds: add,
                                removeFromLibraryIds: remove,
                              );
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
