import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/app_l10n.dart';

/// Phase 4.3 — Timeline quick capture 입력.
class TimelineQuickCaptureResult {
  const TimelineQuickCaptureResult({
    required this.title,
    required this.body,
    required this.occurredAt,
    this.entityId,
  });

  final String title;
  final String body;
  final DateTime occurredAt;
  final String? entityId;
}

/// 제목·본문·(선택) 작품 연결 — Journal First quick capture.
Future<TimelineQuickCaptureResult?> showTimelineQuickCaptureDialog(
  BuildContext context, {
  List<AkashaItem> linkedWorks = const [],
}) async {
  final l10n = lookupAppL10n(context);
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  String? selectedWorkId;

  final works = linkedWorks
      .where((item) => item.workId.trim().isNotEmpty)
      .toList(growable: false);

  final result = await showDialog<TimelineQuickCaptureResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) {
        return AlertDialog(
          title: Text(l10n?.timelineQuickCaptureTitle ?? '타임라인 기록'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: bodyCtrl,
                    autofocus: true,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: l10n?.labelBody ?? '본문',
                      hintText: l10n?.hintTimelineBody ?? '오늘의 생각, 일기, 아이디어…',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: l10n?.labelTitleOptional ?? '제목 (선택)',
                      hintText: l10n?.hintTitleAutoFill ?? '비우면 본문 앞부분을 사용합니다',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (works.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedWorkId,
                      decoration: InputDecoration(
                        labelText: l10n?.labelWorkLinkOptional ?? '작품 연결 (선택)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n?.optionNoLink ?? '연결 없음'),
                        ),
                        ...works.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item.workId,
                            child: Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setLocalState(() => selectedWorkId = value),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n?.timelineSaveLocationInfo ??
                        'vault/timeline/ 에 저장됩니다.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AkashaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.actionCancel ?? '취소'),
            ),
            FilledButton(
              onPressed: () {
                final body = bodyCtrl.text.trim();
                if (body.isEmpty) return;

                var title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  title = body.length <= 40
                      ? body
                      : '${body.substring(0, 40)}…';
                }

                Navigator.pop(
                  ctx,
                  TimelineQuickCaptureResult(
                    title: title,
                    body: body,
                    occurredAt: DateTime.now(),
                    entityId: selectedWorkId?.trim().isNotEmpty == true
                        ? selectedWorkId!.trim()
                        : null,
                  ),
                );
              },
              child: Text(l10n?.actionSave ?? '저장'),
            ),
          ],
        );
      },
    ),
  );

  return result;
}
