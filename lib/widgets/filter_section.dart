import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../utils/helpers.dart';

// ════════════════════════════════════════════════════════════════
//  필터 섹션 위젯 (지능형 중첩 필터링)
// ════════════════════════════════════════════════════════════════

class FilterSection extends StatelessWidget {
  final AppDomain? selectedDomain;
  final MediaCategory? selectedCategory;
  final Set<String> selectedWorkStatuses;
  final Set<String> selectedMyStatuses;
  final SortCriteria sortCriteria;

  final ValueChanged<AppDomain?> onDomainChanged;
  final ValueChanged<MediaCategory?> onCategoryChanged;
  final ValueChanged<String> onToggleWorkStatus;
  final ValueChanged<String> onToggleMyStatus;
  final ValueChanged<SortCriteria> onSortChanged;

  const FilterSection({
    super.key,
    required this.selectedDomain,
    required this.selectedCategory,
    required this.selectedWorkStatuses,
    required this.selectedMyStatuses,
    required this.sortCriteria,
    required this.onDomainChanged,
    required this.onCategoryChanged,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCategories = MediaCategory.values;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. 대분류 (도메인) 필터 + 정렬 ──
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        label: '전체',
                        selected: selectedDomain == null,
                        onTap: () => onDomainChanged(null),
                      ),
                      const SizedBox(width: 6),
                      ...AppDomain.values.map(
                        (dom) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _chip(
                            label: dom.label,
                            icon: dom.icon,
                            selected: selectedDomain == dom,
                            onTap: () => onDomainChanged(dom),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 정렬 드롭다운
              _sortDropdown(context),
            ],
          ),

          const SizedBox(height: 8),

          // ── 2. 소분류 (카테고리) 필터 ──
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        label: selectedDomain == null ? '매체 전체' : '${selectedDomain!.label} 전체',
                        selected: selectedCategory == null,
                        onTap: () => onCategoryChanged(null),
                        small: true,
                      ),
                      const SizedBox(width: 6),
                      ...visibleCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _chip(
                            label: cat.label,
                            icon: cat.icon,
                            selected: selectedCategory == cat,
                            onTap: () => onCategoryChanged(cat),
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

          // ── 상태 필터 (카테고리 선택 시에만 활성화) ──
          if (selectedCategory != null) ...[
            const SizedBox(height: 10),
            _buildStatusFilters(context),
          ],

          // ── 전체 선택 시 안내 텍스트 ──
          if (selectedCategory == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '💡  매체(만화, 게임 등)를 선택하시면 세부 상태(완결여부, 플레이/감상 상태) 필터가 활성화됩니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final workOpts = workStatusOptionsFor(selectedCategory!);
    final myOpts = myStatusOptionsFor(selectedCategory!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 작품 상태
        Row(
          children: [
            Text('작품 상태',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            ...workOpts.map((label) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _chip(
                    label: label,
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
            Text('나의 상태',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
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
                              label: label,
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

  Widget _sortDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortCriteria>(
          value: sortCriteria,
          isDense: true,
          icon: const Icon(Icons.sort, size: 16),
          style: TextStyle(fontSize: 12, color: Colors.grey[300]),
          dropdownColor: const Color(0xFF2A2A3E),
          items: SortCriteria.values
              .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) onSortChanged(v);
          },
        ),
      ),
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
