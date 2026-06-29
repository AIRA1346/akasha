part of 'markdown_body_editor.dart';

class _MarkdownFindBar extends StatelessWidget {
  const _MarkdownFindBar({
    required this.findController,
    required this.replaceController,
    required this.findFocusNode,
    required this.matchCount,
    required this.onFindNext,
    required this.onFindPrevious,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
    required this.onChanged,
  });

  final TextEditingController findController;
  final TextEditingController replaceController;
  final FocusNode findFocusNode;
  final int matchCount;
  final VoidCallback onFindNext;
  final VoidCallback onFindPrevious;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AkashaColors.editorPanelBg,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: findController,
                focusNode: findFocusNode,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onFindNext(),
                style: AkashaTypography.editorFindInput,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '찾기',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              findController.text.isEmpty ? '' : '$matchCount',
              style: AkashaTypography.editorStatus,
            ),
            IconButton(
              onPressed: onFindPrevious,
              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
              tooltip: '이전',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onFindNext,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              tooltip: '다음',
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: replaceController,
                style: AkashaTypography.editorFindInput,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '바꿀 텍스트',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: onReplace, child: const Text('바꾸기')),
            TextButton(onPressed: onReplaceAll, child: const Text('전체')),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
              tooltip: '닫기',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
