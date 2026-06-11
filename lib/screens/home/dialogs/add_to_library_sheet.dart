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
}) async {
  final curated = membership.curatedLibraries;
  if (curated.isEmpty) return;

  final initiallyIn = membership.librariesContaining(workId);
  final checked = <String, bool>{
    for (final lib in curated) lib.id: initiallyIn.contains(lib.id),
  };

  final sorted = List<PersonalLibraryConfig>.from(curated)
    ..sort((a, b) {
      if (activeLibraryId != null) {
        if (a.id == activeLibraryId) return -1;
        if (b.id == activeLibraryId) return 1;
      }
      return a.name.compareTo(b.name);
    });

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
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
                const SizedBox(height: 12),
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
                      onPressed: () async {
                        final add = <String>{};
                        final remove = <String>{};
                        for (final lib in curated) {
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
