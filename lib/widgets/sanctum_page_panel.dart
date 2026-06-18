import 'package:flutter/material.dart';

import 'markdown_body_editor.dart';
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
  final bool isDirty;
  final bool externalChangePending;
  final VoidCallback? onReloadFromDisk;
  final VoidCallback? onDismissExternalChange;
  final DateTime? lastSavedAt;

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
    this.isDirty = false,
    this.externalChangePending = false,
    this.onReloadFromDisk,
    this.onDismissExternalChange,
    this.lastSavedAt,
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
        if (view == SanctumPageView.body && externalChangePending)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.sync_problem,
                        size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '외부에서 md 파일이 변경되었습니다.',
                        style: TextStyle(fontSize: 11, color: Colors.amber[100]),
                      ),
                    ),
                    TextButton(
                      onPressed: onDismissExternalChange,
                      child: const Text('유지', style: TextStyle(fontSize: 11)),
                    ),
                    FilledButton(
                      onPressed: onReloadFromDisk,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('다시 불러오기', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (view == SanctumPageView.body)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              '마크다운 본문을 편집합니다. 메타데이터(평점·태그 등)는 왼쪽 작품 정보, YAML은 「.md」 탭에서 다룹니다.',
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
          child: MarkdownBodyEditor(
            controller: bodyController,
            onChanged: onBodyChanged,
            isDirty: isDirty,
            mdFilePath: mdFilePath,
            lastSavedAt: lastSavedAt,
          ),
        );
      case SanctumPageView.file:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: MarkdownBodyEditor(
            controller: fileController,
            onChanged: onFileChanged,
            isDirty: isDirty,
            mdFilePath: mdFilePath,
            lastSavedAt: lastSavedAt,
            mode: MarkdownEditorMode.fullFile,
          ),
        );
    }
  }
}
