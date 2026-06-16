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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _metaChip(icon: item.domain.icon, label: item.domain.label),
            _metaChip(icon: item.category.icon, label: item.category.label),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: titleCtrl,
          onChanged: (_) => onMarkDirty(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
        if (metaLine.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            metaLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            InteractiveStarRating(
              rating: draftRating,
              size: 18,
              onChanged: (v) {
                onDraftRatingChanged(v);
                onMarkDirty();
              },
            ),
            const Spacer(),
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Switch(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: draftHallOfFame,
                  onChanged: (v) {
                    onDraftHallOfFameChanged(v);
                    onMarkDirty();
                  },
                ),
              ),
            ),
            Text(
              'HoF',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _statusDropdown(
                label: '작품',
                value: draftWorkStatus,
                options: item.workStatusOptions,
                onChanged: (v) {
                  onDraftWorkStatusChanged(v);
                  onMarkDirty();
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _statusDropdown(
                label: '나의',
                value: draftMyStatus,
                options: item.myStatusOptions,
                onChanged: (v) {
                  onDraftMyStatusChanged(v);
                  onMarkDirty();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '태그',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        EditableTagChips(
          tags: draftTags,
          registryTags: registryTags,
          onChanged: (tags) {
            onDraftTagsChanged(tags);
            onMarkDirty();
          },
        ),
        const SizedBox(height: 8),
        if (showAddToLibrary) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToLibrary,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 16),
              label: Text(isArchived ? '서재에 담기' : '저장하고 서재에 담기'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 11),
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
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
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isArchived ? 'md 저장' : 'md 생성'),
              ),
            ),
          ],
        ),
      ],
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
}
