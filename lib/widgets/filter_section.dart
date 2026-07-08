import 'package:flutter/material.dart';
import '../models/browse_entity_scope.dart';
import '../theme/akasha_colors.dart';
import '../models/enums.dart';
import '../utils/helpers.dart';
import '../utils/app_l10n.dart';
import '../generated/l10n/app_localizations.dart';

// ════════════════════════════════════════════════════════════════
//  필터 섹션 위젯 (지능형 중첩 필터링 - 다중 카테고리 지원)
// ════════════════════════════════════════════════════════════════

extension BrowseEntityScopeLocalization on BrowseEntityScope {
  String toLocalizedLabel(AppLocalizations? l10n) {
    switch (this) {
      case BrowseEntityScope.all:
        return l10n?.filterScopeAll ?? '전체';
      case BrowseEntityScope.work:
        return 'Work';
      case BrowseEntityScope.person:
        return 'Person';
      case BrowseEntityScope.concept:
        return 'Concept';
      case BrowseEntityScope.event:
        return 'Event';
      case BrowseEntityScope.place:
        return 'Place';
      case BrowseEntityScope.organization:
        return 'Org';
    }
  }
}

String localizeStatusLabel(String label, AppLocalizations? l10n) {
  if (l10n == null) return label;
  
  // Find in ContentWorkStatus
  for (final status in ContentWorkStatus.values) {
    if (status.label == label) return status.localizedLabel(l10n);
  }
  // Find in ContentMyStatus
  for (final status in ContentMyStatus.values) {
    if (status.label == label) return status.localizedLabel(l10n);
  }
  // Find in GameWorkStatus
  for (final status in GameWorkStatus.values) {
    if (status.label == label) return status.localizedLabel(l10n);
  }
  // Find in GameMyStatus
  for (final status in GameMyStatus.values) {
    if (status.label == label) return status.localizedLabel(l10n);
  }
  
  return label;
}

class FilterSection extends StatelessWidget {
  final Set<MediaCategory> selectedCategories; // 변경: 다중 카테고리 지원
  final Set<String> selectedWorkStatuses;
  final Set<String> selectedMyStatuses;

  final ValueChanged<MediaCategory> onToggleCategory; // 변경: 카테고리 토글 콜백
  final VoidCallback onClearCategories; // 변경: 카테고리 전체 클리어
  final ValueChanged<String> onToggleWorkStatus;
  final ValueChanged<String> onToggleMyStatus;
  final BrowseEntityScope selectedEntityScope;
  final ValueChanged<BrowseEntityScope> onEntityScopeChanged;

  const FilterSection({
    super.key,
    required this.selectedCategories,
    required this.selectedWorkStatuses,
    required this.selectedMyStatuses,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.selectedEntityScope,
    required this.onEntityScopeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCategories = MediaCategory.values;
    final l10n = lookupAppL10n(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BrowseEntityScope.values.map((scope) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _chip(
                    label: scope.toLocalizedLabel(l10n),
                    selected: selectedEntityScope == scope,
                    onTap: () => onEntityScopeChanged(scope),
                    small: true,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (selectedEntityScope.showsWorkGrid) ...[
          // ── 매체 (카테고리) 필터 ──
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        label: l10n?.filterAllMedia ?? '매체 전체',
                        selected: selectedCategories.isEmpty,
                        onTap: onClearCategories,
                        small: true,
                      ),
                      const SizedBox(width: 6),
                      ...visibleCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _chip(
                            label: cat.localizedLabel(l10n),
                            icon: cat.icon,
                            selected: selectedCategories.contains(cat),
                            onTap: () => onToggleCategory(cat),
                            small: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── 상태 필터 (하나 이상의 카테고리 선택 시에만 활성화) ──
          if (selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildStatusFilters(context),
          ],

          // ── 전체 선택 시 안내 텍스트 ──
          if (selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n?.filterStatusHelp ?? '💡  매체(만화, 게임 등)를 선택하시면 세부 상태(완결여부, 플레이/감상 상태) 필터가 활성화됩니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: AkashaColors.textCaption,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ] else ...[
            // ── Entity scope 전용 안내 (Work 필터 대신 높이 유지) ──
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n != null ? l10n.filterEntityGalleryTitle(selectedEntityScope.toLocalizedLabel(l10n)) : '📂  ${selectedEntityScope.label} 아카이브 갤러리',
                style: TextStyle(
                  fontSize: 12,
                  color: AkashaColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final l10n = lookupAppL10n(context);
    // 선택된 모든 카테고리의 옵션들을 모아서 보여줌
    final Set<String> workOpts = {};
    final Set<String> myOpts = {};
    for (final cat in selectedCategories) {
      workOpts.addAll(workStatusOptionsFor(cat));
      myOpts.addAll(myStatusOptionsFor(cat));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 작품 상태
        Row(
          children: [
            Text(l10n?.filterLabelWorkStatus ?? '작품 상태',
                style: TextStyle(
                    fontSize: 11,
                    color: AkashaColors.textMuted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            ...workOpts.map((label) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _chip(
                    label: localizeStatusLabel(label, l10n),
                    selected: selectedWorkStatuses.contains(label),
                    onTap: () => onToggleWorkStatus(label),
                    small: true,
                  ),
                )),
          ],
        ),
        const SizedBox(height: 6),
        // 나의 상태
        Row(
          children: [
            Text(l10n?.filterLabelMyStatus ?? '나의 상태',
                style: TextStyle(
                    fontSize: 11,
                    color: AkashaColors.textMuted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: myOpts
                      .map((label) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _chip(
                              label: localizeStatusLabel(label, l10n),
                              selected: selectedMyStatuses.contains(label),
                              onTap: () => onToggleMyStatus(label),
                              small: true,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontSize: small ? 11 : 13),
      ),
      avatar: icon != null ? Icon(icon, size: 14) : null,
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: small ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}


