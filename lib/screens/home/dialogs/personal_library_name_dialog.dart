import 'package:flutter/material.dart';

import '../../../utils/app_l10n.dart';

/// curated 서재 생성 — 이름만 입력
Future<String?> showPersonalLibraryNameDialog(BuildContext context) async {
  final l10n = lookupAppL10n(context);
  final nameCtrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.personalLibraryAddTitle ?? '➕ 나만의 서재 추가'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n?.labelLibraryName ?? '서재 이름',
            hintText: l10n?.hintLibraryName ?? '예: 인생 명작, 읽을 예정 2026…',
            border: const OutlineInputBorder(),
            isDense: true,
            helperText:
                l10n?.helperLibraryCreate ??
                '만든 뒤 작품을 담아 채웁니다. 필터는 설정에서 조정할 수 있습니다.',
            helperMaxLines: 2,
          ),
          onSubmitted: (v) {
            final name = v.trim();
            if (name.isNotEmpty) Navigator.pop(ctx, name);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n?.actionCancel ?? '취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx, name);
          },
          child: Text(l10n?.actionCreate ?? '만들기'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  return result;
}
