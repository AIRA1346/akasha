import 'package:flutter/material.dart';

import 'vault_markdown_body.dart';

/// Sanctum 4열 — 미리보기 · 본문 편집 · .md 파일 편집
enum SanctumPageView { preview, body, file }

class SanctumPagePanel extends StatelessWidget {
  final SanctumPageView view;
  final ValueChanged<SanctumPageView> onViewChanged;
  final String previewMarkdown;
  final String? mdFilePath;
  final TextEditingController bodyController;
  final TextEditingController fileController;
  final VoidCallback onBodyChanged;
  final VoidCallback onFileChanged;
  final VoidCallback onOpenFileView;

  const SanctumPagePanel({
    super.key,
    required this.view,
    required this.onViewChanged,
    required this.previewMarkdown,
    required this.mdFilePath,
    required this.bodyController,
    required this.fileController,
    required this.onBodyChanged,
    required this.onFileChanged,
    required this.onOpenFileView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 18, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text(
                'Sanctum 페이지',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
              const Spacer(),
              SegmentedButton<SanctumPageView>(
                segments: const [
                  ButtonSegment(
                    value: SanctumPageView.preview,
                    icon: Icon(Icons.visibility_outlined, size: 16),
                    label: Text('보기', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: SanctumPageView.body,
                    icon: Icon(Icons.edit_note_outlined, size: 16),
                    label: Text('본문', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: SanctumPageView.file,
                    icon: Icon(Icons.description_outlined, size: 16),
                    label: Text('.md', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (selected) {
                  final next = selected.first;
                  if (next == SanctumPageView.file) onOpenFileView();
                  onViewChanged(next);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (view == SanctumPageView.body)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              '마크다운 본문을 직접 작성합니다. `# 시놉`, `# 명대사`, `# 메모` 슬롯과 자유 섹션을 모두 편집할 수 있습니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        if (view == SanctumPageView.file)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              'YAML frontmatter + 본문 전체입니다. 왼쪽 「md 저장」으로 vault에 기록됩니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (view) {
      case SanctumPageView.preview:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: VaultMarkdownBody(
            data: previewMarkdown,
            mdFilePath: mdFilePath,
          ),
        );
      case SanctumPageView.body:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TextField(
            controller: bodyController,
            onChanged: (_) => onBodyChanged(),
            maxLines: null,
            expands: true,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontFamily: 'Consolas',
              color: Colors.grey[200],
            ),
            decoration: InputDecoration(
              hintText: '# 📋 시놉시스\n...\n\n# 🎬 명장면 & 명대사\n> ...\n\n# 📝 메모\n...',
              hintStyle: TextStyle(color: Colors.grey[700], height: 1.45),
              filled: true,
              fillColor: const Color(0xFF0E0E16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2D2D44)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2D2D44)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        );
      case SanctumPageView.file:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TextField(
            controller: fileController,
            onChanged: (_) => onFileChanged(),
            maxLines: null,
            expands: true,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontFamily: 'Consolas',
              color: Colors.grey[200],
            ),
            decoration: InputDecoration(
              hintText: '---\nwork_id: ...\n---\n\n# 본문',
              hintStyle: TextStyle(color: Colors.grey[700], height: 1.4),
              filled: true,
              fillColor: const Color(0xFF0E0E16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2D2D44)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2D2D44)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        );
    }
  }
}
