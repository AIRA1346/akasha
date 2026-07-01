part of 'markdown_body_editor.dart';

class _MarkdownEditorStatusBar extends StatelessWidget {
  const _MarkdownEditorStatusBar({
    required this.lineNumber,
    required this.sectionLabel,
    required this.isDirty,
    this.isSaving = false,
    this.lastSavedAt,
    this.hint,
  });

  final int lineNumber;
  final String sectionLabel;
  final bool isDirty;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(
            'Ln $lineNumber',
            style: AkashaTypography.editorStatus,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sectionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AkashaTypography.editorStatus,
            ),
          ),
          if (isSaving)
            Text(
              l10n?.statusSaving ?? '저장 중…',
              style: AkashaTypography.editorSaving,
            )
          else if (!isDirty && lastSavedAt != null)
            Text(
              l10n?.statusSavedText(_formatTime(lastSavedAt!)) ?? '저장됨 ${_formatTime(lastSavedAt!)}',
              style: AkashaTypography.caption,
            ),
          if (hint != null && !isSaving) ...[
            const SizedBox(width: 8),
            Text(
              hint!,
              style: AkashaTypography.caption,
            ),
          ],
          if (isDirty && !isSaving)
            Text(
              l10n?.statusUnsaved ?? '● 미저장',
              style: AkashaTypography.editorDirty,
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
