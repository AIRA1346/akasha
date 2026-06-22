import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/work_link_neighbors_sections.dart';

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
        // —— 작품 헤더 ——
        TextField(
          controller: widget.titleCtrl,
          onChanged: (_) => widget.onMarkDirty(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (alternativeTitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            alternativeTitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          widget.metaLine,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 14),

        // —— 연결 (최상단) ——
        WorkLinkNeighborsSections(
          neighbors: widget.linkNeighbors,
          loading: widget.loadingLinkNeighbors,
          conceptTags: widget.draftTags,
          onOpenEntity: widget.onOpenLinkedEntity,
          onOpenWork: widget.onOpenLinkedWork,
          onLinkCta: widget.onFocusSanctum,
          sectionTitleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C63FF),
          ),
        ),
        if (widget.onGoKnowledgeGraph != null) ...[
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: widget.onGoKnowledgeGraph,
              icon: const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF6C63FF)),
              label: const Text(
                '연결 맵에서 보기',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6C63FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        const Divider(color: Color(0xFF2D2D44), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '노트',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildQuickMemoField(),
        if (widget.notesSection != null) ...[
          const SizedBox(height: 12),
          widget.notesSection!,
        ],

        const SizedBox(height: 8),
        const Divider(color: Color(0xFF2D2D44), height: 1),
        const SizedBox(height: 4),

        // —— 메타데이터 (접힘) ——
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('work_metadata_expansion'),
            initiallyExpanded: _metadataExpanded,
            onExpansionChanged: (v) => setState(() => _metadataExpanded = v),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              '메타데이터',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            children: [
              _buildInfoTable(),
              const SizedBox(height: 12),
              _buildRelatedConceptsEditor(),
              const SizedBox(height: 12),
              _buildOriginalActionsPanel(),
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
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              genre,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildTableRow(
          '원작',
          Text(creator, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
        _buildTableRow(
          '제작사',
          Text(studio, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
        _buildTableRow(
          '평점',
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                ratingValue,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
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
      return Text(
        '설정된 태그가 없습니다',
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      );
    }
    return Column(
      children: concepts.map((tag) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161824),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOriginalActionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showAddToLibrary) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddToLibrary,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 14),
              label: Text(
                widget.isArchived ? '서재에 담기' : '저장하고 서재에 담기',
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onResetToDefaults,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 10),
                ),
                child: const Text('기본값'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: widget.isSaving ? null : widget.onSaveArchive,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E3E),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 10),
                ),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Text(widget.isArchived ? 'md 저장' : 'md 생성'),
              ),
            ),
          ],
        ),
        if (widget.canDeleteMd && widget.onDeleteArchive != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isSaving ? null : widget.onDeleteArchive,
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('md 삭제'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickMemoField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161824),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '상세 기록은 우측 Sanctum에서 작성하세요',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
              child: const Text('기록하기', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }
}
