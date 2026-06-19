import 'package:flutter/material.dart';
import '../models/browse_entity_scope.dart';
import '../models/enums.dart';
import '../utils/helpers.dart';

// ════════════════════════════════════════════════════════════════
//  필터 섹션 위젯 (지능형 중첩 필터링 - 다중 카테고리 지원)
// ════════════════════════════════════════════════════════════════

class FilterSection extends StatelessWidget {
  final AppDomain? selectedDomain;
  final Set<MediaCategory> selectedCategories; // 변경: 다중 카테고리 지원
  final Set<String> selectedWorkStatuses;
  final Set<String> selectedMyStatuses;

  final ValueChanged<AppDomain?> onDomainChanged;
  final ValueChanged<MediaCategory> onToggleCategory; // 변경: 카테고리 토글 콜백
  final VoidCallback onClearCategories; // 변경: 카테고리 전체 클리어
  final ValueChanged<String> onToggleWorkStatus;
  final ValueChanged<String> onToggleMyStatus;
  final BrowseEntityScope selectedEntityScope;
  final ValueChanged<BrowseEntityScope> onEntityScopeChanged;

  const FilterSection({
    super.key,
    required this.selectedDomain,
    required this.selectedCategories,
    required this.selectedWorkStatuses,
    required this.selectedMyStatuses,
    required this.onDomainChanged,
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
                    label: scope.label,
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
          // ── 1. 대분류 (도메인) 필터 ──
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
                        selected: selectedCategories.isEmpty,
                        onTap: onClearCategories,
                        small: true,
                      ),
                      const SizedBox(width: 6),
                      ...visibleCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _chip(
                            label: cat.label,
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
                '💡  매체(만화, 게임 등)를 선택하시면 세부 상태(완결여부, 플레이/감상 상태) 필터가 활성화됩니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
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
