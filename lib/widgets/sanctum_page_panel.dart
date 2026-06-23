import 'package:flutter/material.dart';

import '../core/archiving/record_link.dart';
import '../features/workbench/presentation/widgets/work_sanctum_section_editor.dart';
import '../features/workbench/presentation/workbench_save_status_hint.dart';
import '../models/entity_link_selection.dart';
import '../theme/akasha_colors.dart';
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
  final bool isSaving;
  final bool externalChangePending;
  final VoidCallback? onReloadFromDisk;
  final VoidCallback? onDismissExternalChange;
  final DateTime? lastSavedAt;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;
  final String headerTitle;
  final TextEditingController? titleController;
  final VoidCallback? onTitleChanged;
  final Widget? footer;
  final bool sectionLayout;
  final GlobalKey<WorkSanctumSectionEditorState>? sectionEditorKey;

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
    this.isSaving = false,
    this.externalChangePending = false,
    this.onReloadFromDisk,
    this.onDismissExternalChange,
    this.lastSavedAt,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
    this.headerTitle = '기록 본문',
    this.titleController,
    this.onTitleChanged,
    this.footer,
    this.sectionLayout = false,
    this.sectionEditorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 18, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Text(
                    headerTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[300],
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<SanctumPageView>(
                    segments: [
                      const ButtonSegment(
                        value: SanctumPageView.preview,
                        icon: Icon(Icons.visibility_outlined, size: 16),
                        label: Text('보기', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: SanctumPageView.body,
                        icon: const Icon(Icons.edit_note_outlined, size: 16),
                        label: Text(
                          sectionLayout ? '기록' : '본문',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const ButtonSegment(
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
              if (titleController != null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  onChanged: (_) => onTitleChanged?.call(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '작품 제목',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: WorkbenchSaveStatusHint(
            isDirty: isDirty,
            isSaving: isSaving,
            lastSavedAt: lastSavedAt,
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
              sectionLayout
                  ? '설명·감상을 섹션별로 편집합니다. 고급 편집은 「.md」 탭을 사용하세요.'
                  : '마크다운 본문을 편집합니다. 메타데이터(평점·태그 등)는 왼쪽 작품 정보, YAML은 「.md」 탭에서 다룹니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        if (view == SanctumPageView.file)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              'YAML frontmatter + 본문 전체입니다. 하단 「md 저장」으로 vault에 기록됩니다.',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Expanded(child: _buildContent(context)),
        if (footer != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AkashaColors.workbenchPanel,
              border: Border(top: BorderSide(color: Colors.grey[850]!)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: footer!,
            ),
          ),
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
            onWikiLinkTap: onWikiLinkTap,
          ),
        );
      case SanctumPageView.body:
        if (sectionLayout) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: WorkSanctumSectionEditor(
              key: sectionEditorKey,
              bodyController: bodyController,
              onChanged: onBodyChanged,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: MarkdownBodyEditor(
            controller: bodyController,
            onChanged: onBodyChanged,
            isDirty: isDirty,
            isSaving: isSaving,
            mdFilePath: mdFilePath,
            lastSavedAt: lastSavedAt,
            onRequestEntityLink: onRequestEntityLink,
          ),
        );
      case SanctumPageView.file:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: MarkdownBodyEditor(
            controller: fileController,
            onChanged: onFileChanged,
            isDirty: isDirty,
            isSaving: isSaving,
            mdFilePath: mdFilePath,
            lastSavedAt: lastSavedAt,
            mode: MarkdownEditorMode.fullFile,
          ),
        );
    }
  }
}
