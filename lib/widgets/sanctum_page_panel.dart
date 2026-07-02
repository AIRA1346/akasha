import 'package:flutter/material.dart';

import '../core/archiving/record_link.dart';
import '../core/ports/user_catalog_port.dart';
import '../features/workbench/presentation/widgets/work_sanctum_section_editor.dart';
import '../features/workbench/presentation/workbench_save_status_hint.dart';
import '../services/sanctum_archive_completion.dart';
import 'sanctum/sanctum_archive_completion_bar.dart';
import '../models/entity_link_selection.dart';
import '../models/user_catalog_entity.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_radius.dart';
import '../theme/akasha_spacing.dart';
import '../theme/akasha_typography.dart';
import 'markdown_body_editor.dart';
import 'sanctum/sanctum_preview_body.dart';
import 'vault_markdown_body.dart';
import '../utils/app_l10n.dart';

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
  )?
  onRequestEntityLink;
  final String headerTitle;
  final TextEditingController? titleController;
  final VoidCallback? onTitleChanged;
  final Widget? footer;
  final bool sectionLayout;
  final GlobalKey<WorkSanctumSectionEditorState>? sectionEditorKey;
  final UserCatalogPort? userCatalog;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final String? archiveCompletionBodyRaw;

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
    this.userCatalog,
    this.onOpenLinkedEntity,
    this.archiveCompletionBodyRaw,
  });

  bool get _useRichPreview => sectionLayout || userCatalog != null;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AkashaSpacing.sanctumPanelHeader,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final viewSwitcher = SegmentedButton<SanctumPageView>(
                    segments: [
                      ButtonSegment(
                        value: SanctumPageView.preview,
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: Text(
                          l10n?.tabView ?? '보기',
                          style: AkashaTypography.compactLabel,
                        ),
                      ),
                      ButtonSegment(
                        value: SanctumPageView.body,
                        icon: const Icon(Icons.edit_note_outlined, size: 16),
                        label: Text(
                          sectionLayout
                              ? (l10n?.tabRecord ?? '기록')
                              : (l10n?.tabBody ?? '본문'),
                          style: AkashaTypography.compactLabel,
                        ),
                      ),
                      ButtonSegment(
                        value: SanctumPageView.file,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: Text(
                          '.md',
                          style: AkashaTypography.compactLabel,
                        ),
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
                  );

                  final titleStyle = AkashaTypography.headline.copyWith(
                    fontSize: 14,
                    color: AkashaColors.textPrimary,
                  );

                  if (constraints.maxWidth < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 18,
                              color: palette.accent,
                            ),
                            const SizedBox(width: AkashaSpacing.sm),
                            Expanded(
                              child: Text(
                                headerTitle == '기록 본문'
                                    ? (l10n?.recordBody ?? '기록 본문')
                                    : headerTitle,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AkashaSpacing.sm),
                        viewSwitcher,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          headerTitle == '기록 본문'
                              ? (l10n?.recordBody ?? '기록 본문')
                              : headerTitle,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: viewSwitcher),
                    ],
                  );
                },
              ),
              if (titleController != null) ...[
                SizedBox(height: AkashaSpacing.sm),
                TextField(
                  controller: titleController,
                  onChanged: (_) => onTitleChanged?.call(),
                  style: AkashaTypography.editableTitle,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n?.hintWorkTitle ?? '작품 제목',
                    hintStyle: AkashaTypography.headline.copyWith(
                      color: AkashaColors.textCaption,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AkashaRadius.smBorder,
                      borderSide: BorderSide(
                        color: AkashaColors.borderSubtle(0.08),
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.sm + 2,
                      vertical: AkashaSpacing.sm,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (footer == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: WorkbenchSaveStatusHint(
              isDirty: isDirty,
              isSaving: isSaving,
              lastSavedAt: lastSavedAt,
            ),
          ),
        if (sectionLayout && archiveCompletionBodyRaw != null)
          SanctumArchiveCompletionBar(
            report: SanctumArchiveCompletion.evaluate(
              bodyRaw: archiveCompletionBodyRaw!,
            ),
          ),
        if (view == SanctumPageView.body && externalChangePending)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AkashaColors.statusWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AkashaColors.statusWarning.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_problem,
                      size: 16,
                      color: AkashaColors.statusWarning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.externalFileChanged ?? '외부에서 md 파일이 변경되었습니다.',
                        style: AkashaTypography.bodySecondary.copyWith(
                          color: AkashaColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onDismissExternalChange,
                      child: Text(
                        l10n?.actionKeep ?? '유지',
                        style: AkashaTypography.compactLabel,
                      ),
                    ),
                    FilledButton(
                      onPressed: onReloadFromDisk,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.symmetric(
                          horizontal: AkashaSpacing.sm + 2,
                        ),
                      ),
                      child: Text(
                        l10n?.actionReload ?? '다시 불러오기',
                        style: AkashaTypography.compactLabel,
                      ),
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
                  ? (l10n?.helpSectionEdit ??
                        '설명·감상을 섹션별로 편집합니다. 고급 편집은 「.md」 탭을 사용하세요.')
                  : (l10n?.helpMarkdownBodyEdit ??
                        '마크다운 본문을 편집합니다. 메타데이터(평점·태그 등)는 왼쪽 작품 정보, YAML은 「.md」 탭에서 다룹니다.'),
              style: AkashaTypography.caption,
            ),
          ),
        if (view == SanctumPageView.file)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              l10n?.helpFullFileEdit ??
                  'YAML frontmatter + 본문 전체입니다. 하단 「md 저장」으로 vault에 기록됩니다.',
              style: AkashaTypography.caption,
            ),
          ),
        Expanded(child: _buildContent(context)),
        if (footer != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.workbenchPanel,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
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
          child: _useRichPreview
              ? SanctumPreviewBody(
                  data: previewMarkdown,
                  mdFilePath: mdFilePath,
                  userCatalog: userCatalog,
                  onWikiLinkTap: onWikiLinkTap,
                  onOpenEntity: onOpenLinkedEntity,
                  slotAware: sectionLayout,
                )
              : VaultMarkdownBody(
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
              userCatalog: userCatalog,
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
