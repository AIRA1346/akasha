import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../widgets/editable_tag_chips.dart';
import '../../../widgets/star_rating.dart';

/// 워크벤치 작품정보 패널 — 편집 폼 (제목·평점·상태·태그·액션).
class WorkDetailInfoForm extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    // 1. 시안용 메타데이터
    final alternativeTitle = item.creator.isNotEmpty ? item.creator : 'Original Work';
    final metaLineText = metaLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 제목 필드 (보더리스 형태로 고급스럽게)
        TextField(
          controller: titleCtrl,
          onChanged: (_) => onMarkDirty(),
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
        const SizedBox(height: 4),

        // 대체 타이틀 / 서브 정보
        if (alternativeTitle.isNotEmpty)
          Text(
            alternativeTitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        const SizedBox(height: 2),
        Text(
          metaLineText,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),

        // 액션 버튼 행 (상세 정보, 하트, 더보기)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: FilledButton.icon(
                  onPressed: onSaveArchive,
                  icon: const Icon(Icons.navigate_next_rounded, size: 14),
                  label: const Text('상세 정보', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3FD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.favorite_border_rounded,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              icon: Icons.more_horiz_rounded,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFF2D2D44), height: 1),
        const SizedBox(height: 16),

        // 핵심 정보 테이블
        _buildSectionHeader('핵심 정보'),
        const SizedBox(height: 8),
        _buildInfoTable(),
        const SizedBox(height: 20),

        // 주요 인물
        _buildSectionHeader('주요 인물'),
        const SizedBox(height: 8),
        _buildKeyCharacters(),
        const SizedBox(height: 20),

        // 관련 개념
        _buildSectionHeader('태그'),
        const SizedBox(height: 8),
        _buildRelatedConcepts(),
        const SizedBox(height: 20),

        // 연결된 작품
        _buildSectionHeader('연결된 작품'),
        const SizedBox(height: 8),
        _buildConnectedWorks(),
        const SizedBox(height: 16),

        // 그래프에서 보기 버튼
        SizedBox(
          height: 32,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF6C63FF)),
            label: const Text('그래프에서 보기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFF2D2D44), height: 1),
        const SizedBox(height: 16),

        // 아카이브 기능 보존용 오리지널 기능 버튼 패널
        _buildOriginalActionsPanel(),
        const SizedBox(height: 20),
        _buildQuickMemoField(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoTable() {
    final genre = item.category.name;
    final creator = item.creator.isNotEmpty ? item.creator : '정보 없음';
    final studio = '정보 없음';
    final ratingValue = draftRating > 0 ? draftRating.toStringAsFixed(1) : '평가 없음';

    return Table(
      columnWidths: {
        0: const FixedColumnWidth(64),
        1: const FlexColumnWidth(),
      },
      children: [
        _buildTableRow('장로', Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            genre,
            style: const TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          ),
        )),
        _buildTableRow('원작', Text(creator, style: const TextStyle(fontSize: 10, color: Colors.white))),
        _buildTableRow('제작사', Text(studio, style: const TextStyle(fontSize: 10, color: Colors.white))),
        _buildTableRow('평점', Row(
          children: [
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              ratingValue,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        )),
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

  Widget _buildKeyCharacters() {
    final characters = [
      _CharData('인물 정보 없음', '캐릭터'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: characters.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF222533),
                  child: Text(
                    c.name.substring(0, 1),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.name,
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  c.role,
                  style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRelatedConcepts() {
    final concepts = draftTags;
    if (concepts.isEmpty) {
      return Text('설정된 태그가 없습니다', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
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
          child: Row(
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       tag,
                       style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                     ),
                     const SizedBox(height: 2),
                     Text(
                       _getTagSubLabel(tag),
                       style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                     ),
                   ],
                 ),
               ),
               Icon(Icons.navigate_next_rounded, size: 14, color: Colors.grey[600]),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getTagSubLabel(String tag) {
    switch (tag) {
      case '마녀교':
        return '용어 · 조직';
      case '사망 회귀':
        return '능력 · 설정';
      case '마녀':
        return '인물 군상';
      case '성역':
        return '장소 · 설정';
      default:
        return '태그 · 관련 개념';
    }
  }

  Widget _buildConnectedWorks() {
    final works = [
      _ConnectedData('연결된 작품 없음', '', ''),
    ];

    return Column(
      children: works.map((w) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 24,
                  height: 32,
                  child: w.imageUrl.isNotEmpty
                      ? Image.network(
                          w.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF222533),
                            child: const Center(child: Icon(Icons.movie_outlined, size: 12, color: Colors.grey)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF222533),
                          child: const Center(child: Icon(Icons.movie_outlined, size: 12, color: Colors.grey)),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  w.title,
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              if (w.match.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    w.match,
                    style: TextStyle(fontSize: 8, color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOriginalActionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 원본 태그 및 평점 수정 컨트롤 보존 (인터랙션 백엔드 보존)
        if (showAddToLibrary) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToLibrary,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 14),
              label: Text(isArchived ? '서재에 담기' : '저장하고 서재에 담기'),
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
                onPressed: onResetToDefaults,
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
                onPressed: isSaving ? null : onSaveArchive,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E3E),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 10),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Text(isArchived ? 'md 저장' : 'md 생성'),
              ),
            ),
          ],
        ),
        if (canDeleteMd && onDeleteArchive != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onDeleteArchive,
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

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 14, color: Colors.white),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3A3A52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.tealAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _statusDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final safeOptions = options.isEmpty ? [value] : options;
    final resolved =
        safeOptions.contains(value) ? value : safeOptions.first;

    return DropdownButtonFormField<String>(
      initialValue: resolved,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 10, height: 1.1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      items: safeOptions
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
            child: TextField(
              maxLines: null,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                hintText: '메모를 추가하세요...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharData {
  const _CharData(this.name, this.role);
  final String name;
  final String role;
}

class _ConnectedData {
  const _ConnectedData(this.title, this.match, this.imageUrl);
  final String title;
  final String match;
  final String imageUrl;
}
