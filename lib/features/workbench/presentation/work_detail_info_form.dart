import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/work_link_neighbors_sections.dart';
import 'widgets/workbench_panel_styles.dart';

/// 워크벤치 작품정보 패널 — 연결 우선 레이아웃.
class WorkDetailInfoForm extends StatefulWidget {
  const WorkDetailInfoForm({
    super.key,
    required this.item,
    required this.metaLine,
    required this.titleCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
    required this.registryTags,
    required this.isSaving,
    required this.isArchived,
    this.isDirty = false,
    this.lastSavedAt,
    required this.showAddToLibrary,
    required this.onMarkDirty,
    required this.onDraftRatingChanged,
    required this.onDraftWorkStatusChanged,
    required this.onDraftMyStatusChanged,
    required this.onDraftHallOfFameChanged,
    required this.onDraftTagsChanged,
    required this.onResetToDefaults,
    required this.onSaveArchive,
    required this.onAddToLibrary,
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.linkNeighbors = const WorkLinkNeighbors(),
    this.loadingLinkNeighbors = false,
    this.onOpenLinkedEntity,
    this.onOpenLinkedWork,
    this.onGoKnowledgeGraph,
    this.onFocusSanctum,
    this.notesSection,
  });

  final AkashaItem item;
  final String metaLine;
  final TextEditingController titleCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;
  final Set<String> registryTags;
  final bool isSaving;
  final bool isArchived;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final bool showAddToLibrary;
  final VoidCallback onMarkDirty;
  final ValueChanged<double> onDraftRatingChanged;
  final ValueChanged<String> onDraftWorkStatusChanged;
  final ValueChanged<String> onDraftMyStatusChanged;
  final ValueChanged<bool> onDraftHallOfFameChanged;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onResetToDefaults;
  final VoidCallback onSaveArchive;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final WorkLinkNeighbors linkNeighbors;
  final bool loadingLinkNeighbors;
  final void Function(UserCatalogEntity entity)? onOpenLinkedEntity;
  final void Function(AkashaItem work)? onOpenLinkedWork;
  final VoidCallback? onGoKnowledgeGraph;
  final VoidCallback? onFocusSanctum;
  final Widget? notesSection;

  @override
  State<WorkDetailInfoForm> createState() => _WorkDetailInfoFormState();
}

class _WorkDetailInfoFormState extends State<WorkDetailInfoForm> {
  bool _metadataExpanded = false;

  @override
  Widget build(BuildContext context) {
    final alternativeTitle =
        widget.item.creator.isNotEmpty ? widget.item.creator : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.titleCtrl,
          onChanged: (_) => widget.onMarkDirty(),
          style: AkashaTypography.headlineEditable,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (alternativeTitle.isNotEmpty) ...[
          const SizedBox(height: AkashaSpacing.xs),
          Text(alternativeTitle, style: AkashaTypography.bodySecondary),
        ],
        const SizedBox(height: 2),
        Text(widget.metaLine, style: AkashaTypography.bodySecondary),
        const SizedBox(height: AkashaSpacing.md),

        WorkbenchPanelStyles.connectionsHeader(),
        const SizedBox(height: AkashaSpacing.sm),
        WorkLinkNeighborsSections(
          neighbors: widget.linkNeighbors,
          loading: widget.loadingLinkNeighbors,
          conceptTags: widget.draftTags,
          onOpenEntity: widget.onOpenLinkedEntity,
          onOpenWork: widget.onOpenLinkedWork,
          onLinkCta: widget.onFocusSanctum,
          sectionTitleStyle: AkashaTypography.sectionTitle,
        ),
        if (widget.onGoKnowledgeGraph != null) ...[
          const SizedBox(height: AkashaSpacing.xs),
          WorkbenchPanelStyles.graphListButton(
            onPressed: widget.onGoKnowledgeGraph!,
          ),
          const SizedBox(height: AkashaSpacing.md),
        ],

        WorkbenchPanelStyles.panelDivider(vertical: AkashaSpacing.sm),
        WorkbenchPanelStyles.sectionLabel('노트'),
        const SizedBox(height: AkashaSpacing.sm),
        _buildQuickMemoField(),
        if (widget.notesSection != null) ...[
          const SizedBox(height: AkashaSpacing.md),
          widget.notesSection!,
        ],

        WorkbenchPanelStyles.panelDivider(),
        WorkbenchSaveActions(
          isSaving: widget.isSaving,
          isDirty: widget.isDirty,
          lastSavedAt: widget.lastSavedAt,
          saveLabel: widget.isArchived ? 'md 저장' : 'md 생성',
          onSave: widget.onSaveArchive,
          showAddToLibrary: widget.showAddToLibrary,
          libraryLabel: widget.isArchived
              ? '서재에 담기'
              : '저장하고 서재에 담기',
          onAddToLibrary: widget.onAddToLibrary,
          showReset: true,
          onReset: widget.onResetToDefaults,
          canDeleteMd: widget.canDeleteMd,
          onDeleteArchive: widget.onDeleteArchive,
        ),

        const SizedBox(height: AkashaSpacing.md),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('work_metadata_expansion'),
            initiallyExpanded: _metadataExpanded,
            onExpansionChanged: (v) => setState(() => _metadataExpanded = v),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
            title: Text(
              '메타데이터',
              style: AkashaTypography.bodySecondary.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              _buildInfoTable(),
              const SizedBox(height: AkashaSpacing.md),
              _buildRelatedConceptsEditor(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTable() {
    final genre = widget.item.category.name;
    final creator =
        widget.item.creator.isNotEmpty ? widget.item.creator : '정보 없음';
    const studio = '정보 없음';
    final ratingValue = widget.draftRating > 0
        ? widget.draftRating.toStringAsFixed(1)
        : '평가 없음';

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(64),
        1: FlexColumnWidth(),
      },
      children: [
        _buildTableRow(
          '장르',
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AkashaColors.personAccent.withValues(alpha: 0.1),
              borderRadius: AkashaRadius.smBorder,
            ),
            child: Text(
              genre,
              style: AkashaTypography.caption.copyWith(
                color: AkashaColors.personAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildTableRow(
          '원작',
          Text(creator, style: AkashaTypography.caption.copyWith(
            color: AkashaColors.textPrimary,
          )),
        ),
        _buildTableRow(
          '제작사',
          Text(studio, style: AkashaTypography.caption.copyWith(
            color: AkashaColors.textPrimary,
          )),
        ),
        _buildTableRow(
          '평점',
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: AkashaSpacing.xs),
              Text(
                ratingValue,
                style: AkashaTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AkashaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, Widget content) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: AkashaTypography.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedConceptsEditor() {
    final concepts = widget.draftTags;
    if (concepts.isEmpty) {
      return Text('설정된 태그가 없습니다', style: AkashaTypography.caption);
    }
    return Column(
      children: concepts.map((tag) {
        return Container(
          margin: const EdgeInsets.only(bottom: AkashaSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AkashaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AkashaColors.surface,
            borderRadius: AkashaRadius.mdBorder,
            border: Border.all(color: AkashaColors.borderSubtle(0.04)),
          ),
          child: Text(
            tag,
            style: AkashaTypography.sectionTitle.copyWith(
              color: AkashaColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickMemoField() {
    return Container(
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AkashaSpacing.md,
        vertical: AkashaSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 18, color: AkashaColors.textMuted),
          const SizedBox(width: AkashaSpacing.sm),
          Expanded(
            child: Text(
              '상세 기록은 우측 기록 본문에서 작성하세요',
              style: AkashaTypography.caption,
            ),
          ),
          if (widget.onFocusSanctum != null)
            TextButton(
              onPressed: widget.onFocusSanctum,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('기록하기', style: AkashaTypography.caption),
            ),
        ],
      ),
    );
  }
}
