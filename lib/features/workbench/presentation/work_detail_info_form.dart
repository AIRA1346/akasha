import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/star_rating.dart';
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
    this.hideConnectionsSection = false,
    this.summaryLayout = false,
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
  final bool hideConnectionsSection;
  final bool summaryLayout;

  @override
  State<WorkDetailInfoForm> createState() => _WorkDetailInfoFormState();
}

class _WorkDetailInfoFormState extends State<WorkDetailInfoForm> {
  bool _metadataExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final alternativeTitle = widget.item.creator.isNotEmpty
        ? widget.item.creator
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.summaryLayout) ...[
          Text(
            widget.titleCtrl.text.trim().isNotEmpty
                ? widget.titleCtrl.text.trim()
                : widget.item.title,
            style: AkashaTypography.headlineEditable,
          ),
        ] else
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

        if (!widget.hideConnectionsSection) ...[
          WorkbenchPanelStyles.connectionsHeader(),
          const SizedBox(height: AkashaSpacing.sm),
          WorkLinkNeighborsSections(
            neighbors: widget.linkNeighbors,
            loading: widget.loadingLinkNeighbors,
            conceptTags: widget.draftTags,
            sourceWork: widget.item,
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
        ] else ...[
          _buildInfoTable(l10n),
          if (widget.draftTags.isNotEmpty) ...[
            const SizedBox(height: AkashaSpacing.sm),
            Text(l10n?.labelTags ?? '태그', style: AkashaTypography.sectionLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.draftTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: palette.workbenchTile,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AkashaSpacing.md),
        ],

        WorkbenchPanelStyles.panelDivider(vertical: AkashaSpacing.sm),
        WorkbenchPanelStyles.sectionLabel(l10n?.tabMemo ?? '메모'),
        const SizedBox(height: AkashaSpacing.sm),
        _buildQuickMemoField(l10n),
        if (widget.notesSection != null && !widget.summaryLayout) ...[
          const SizedBox(height: AkashaSpacing.md),
          widget.notesSection!,
        ],

        if (!widget.summaryLayout) ...[
          WorkbenchPanelStyles.panelDivider(),
          WorkbenchSaveActions(
            isSaving: widget.isSaving,
            isDirty: widget.isDirty,
            lastSavedAt: widget.lastSavedAt,
            saveLabel: widget.isArchived ? (l10n?.actionSaveMd ?? 'md 저장') : (l10n?.actionCreateMd ?? 'md 생성'),
            onSave: widget.onSaveArchive,
            showAddToLibrary: widget.showAddToLibrary,
            libraryLabel: widget.isArchived ? (l10n?.actionAddToLibrary ?? '서재에 담기') : (l10n?.actionSaveAndAddToLibrary ?? '저장하고 서재에 담기'),
            onAddToLibrary: widget.onAddToLibrary,
            showReset: true,
            onReset: widget.onResetToDefaults,
            canDeleteMd: widget.canDeleteMd,
            onDeleteArchive: widget.onDeleteArchive,
          ),
        ],

        if (!widget.summaryLayout) ...[
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
                l10n?.labelMetadata ?? '메타데이터',
                style: AkashaTypography.bodySecondary.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                if (!widget.hideConnectionsSection) _buildInfoTable(l10n),
                if (!widget.hideConnectionsSection)
                  const SizedBox(height: AkashaSpacing.md),
                _buildRelatedConceptsEditor(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTable(dynamic l10n) {
    final palette = context.akashaPalette;
    final genre = widget.item.category.localizedLabel(l10n);
    final creator = widget.item.creator.isNotEmpty
        ? widget.item.creator
        : (l10n?.previewInfoNone ?? '정보 없음');
    final studio = l10n?.previewInfoNone ?? '정보 없음';

    return Table(
      columnWidths: const {0: FixedColumnWidth(64), 1: FlexColumnWidth()},
      children: [
        _buildTableRow(
          l10n?.labelCategory ?? '장르',
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: AkashaRadius.smBorder,
            ),
            child: Text(
              genre,
              style: AkashaTypography.caption.copyWith(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildTableRow(
          l10n?.labelCreator ?? '원작',
          Text(
            creator,
            style: AkashaTypography.caption.copyWith(
              color: AkashaColors.textPrimary,
            ),
          ),
        ),
        _buildTableRow(
          l10n?.previewStudio ?? '제작사',
          Text(
            studio,
            style: AkashaTypography.caption.copyWith(
              color: AkashaColors.textPrimary,
            ),
          ),
        ),
        _buildTableRow(l10n?.previewRating ?? '평점', _buildRatingEditor(l10n)),
        _buildTableRow(
          l10n?.labelWorkStatus ?? '작품 상태',
          _buildStatusDropdown(
            value: _resolvedWorkStatusValue(),
            options: widget.item.workStatusOptions,
            labelFor: (value) => _localizedWorkStatus(value, l10n),
            onChanged: (value) {
              widget.onDraftWorkStatusChanged(value);
              widget.onMarkDirty();
            },
          ),
        ),
        _buildTableRow(
          l10n?.labelMyStatus ?? '나의 상태',
          _buildStatusDropdown(
            value: _resolvedMyStatusValue(),
            options: widget.item.myStatusOptions,
            labelFor: (value) => _localizedMyStatus(value, l10n),
            onChanged: (value) {
              widget.onDraftMyStatusChanged(value);
              widget.onMarkDirty();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingEditor(dynamic l10n) {
    final ratingText = widget.draftRating > 0
        ? widget.draftRating.toStringAsFixed(1)
        : (l10n?.previewNoRating ?? '평가 없음');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InteractiveStarRating(
          rating: widget.draftRating,
          size: 18,
          onChanged: (value) {
            widget.onDraftRatingChanged(value);
            widget.onMarkDirty();
          },
        ),
        const SizedBox(width: AkashaSpacing.xs),
        Flexible(
          child: Text(
            ratingText,
            overflow: TextOverflow.ellipsis,
            style: AkashaTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AkashaColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required List<String> options,
    required String Function(String value) labelFor,
    required ValueChanged<String> onChanged,
  }) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    if (options.isEmpty || value.isEmpty) {
      return Text(l10n?.previewInfoNone ?? '정보 없음', style: AkashaTypography.caption);
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        dropdownColor: palette.workbenchTile,
        style: AkashaTypography.caption.copyWith(
          color: AkashaColors.textPrimary,
        ),
        iconSize: 16,
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(labelFor(option), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  String _resolvedWorkStatusValue() {
    return _resolveStatusValue(
      widget.draftWorkStatus,
      widget.item.workStatusOptions,
      isWorkStatus: true,
    );
  }

  String _resolvedMyStatusValue() {
    return _resolveStatusValue(
      widget.draftMyStatus,
      widget.item.myStatusOptions,
      isWorkStatus: false,
    );
  }

  String _resolveStatusValue(
    String raw,
    List<String> options, {
    required bool isWorkStatus,
  }) {
    if (options.isEmpty) return '';
    if (options.contains(raw)) return raw;

    final normalized = widget.item.category.isContentType
        ? (isWorkStatus
              ? ContentWorkStatus.fromStorage(raw).label
              : ContentMyStatus.fromStorage(raw).label)
        : (isWorkStatus
              ? GameWorkStatus.fromStorage(raw).label
              : GameMyStatus.fromStorage(raw).label);

    return options.contains(normalized) ? normalized : options.first;
  }

  String _localizedWorkStatus(String value, dynamic l10n) {
    if (l10n == null) return value;
    return widget.item.category.isContentType
        ? ContentWorkStatus.fromStorage(value).localizedLabel(l10n)
        : GameWorkStatus.fromStorage(value).localizedLabel(l10n);
  }

  String _localizedMyStatus(String value, dynamic l10n) {
    if (l10n == null) return value;
    return widget.item.category.isContentType
        ? ContentMyStatus.fromStorage(value).localizedLabel(l10n)
        : GameMyStatus.fromStorage(value).localizedLabel(l10n);
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
          child: Align(alignment: Alignment.centerLeft, child: content),
        ),
      ],
    );
  }

  Widget _buildRelatedConceptsEditor() {
    final palette = context.akashaPalette;
    final concepts = widget.draftTags;
    final l10n = lookupAppL10n(context);
    if (concepts.isEmpty) {
      return Text(l10n?.previewNoTags ?? '설정된 태그가 없습니다', style: AkashaTypography.caption);
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
            color: palette.workbenchTile,
            borderRadius: AkashaRadius.mdBorder,
            border: Border.all(color: palette.borderSubtle(0.18)),
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

  Widget _buildQuickMemoField(dynamic l10n) {
    final palette = context.akashaPalette;
    return InkWell(
      onTap: widget.onFocusSanctum,
      borderRadius: AkashaRadius.mdBorder,
      child: Container(
        decoration: BoxDecoration(
          color: palette.workbenchTile,
          borderRadius: AkashaRadius.mdBorder,
          border: Border.all(color: palette.borderSubtle(0.2)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AkashaSpacing.md,
          vertical: AkashaSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 18,
              color: AkashaColors.textMuted,
            ),
            const SizedBox(width: AkashaSpacing.sm),
            Expanded(
              child: Text(
                widget.summaryLayout
                    ? (l10n?.helpMemoEditInBody ?? '메모 · 본문에서 편집')
                    : (l10n?.helpMemoWriteInBody ?? '상세 기록은 우측 기록 본문에서 작성하세요'),
                style: AkashaTypography.caption,
              ),
            ),
            if (widget.onFocusSanctum != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AkashaColors.textCaption,
              ),
          ],
        ),
      ),
    );
  }
}
