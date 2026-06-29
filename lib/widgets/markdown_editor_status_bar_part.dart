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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(
            'Ln $lineNumber',
            style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sectionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
            ),
          ),
          if (isSaving)
            Text(
              '저장 중…',
              style: TextStyle(fontSize: 10, color: Colors.tealAccent),
            )
          else if (!isDirty && lastSavedAt != null)
            Text(
              '저장됨 ${_formatTime(lastSavedAt!)}',
              style: TextStyle(fontSize: 10, color: AkashaColors.textCaption),
            ),
          if (hint != null && !isSaving) ...[
            const SizedBox(width: 8),
            Text(
              hint!,
              style: TextStyle(fontSize: 10, color: AkashaColors.textCaption),
            ),
          ],
          if (isDirty && !isSaving)
            Text(
              '● 미저장',
              style: TextStyle(
                fontSize: 10,
                color: Colors.amber[700],
                fontWeight: FontWeight.w600,
              ),
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
