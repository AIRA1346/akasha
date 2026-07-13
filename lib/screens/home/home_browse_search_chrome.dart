import 'package:flutter/material.dart';

import '../../core/archiving/entity_anchor.dart';
import '../../models/browse_entity_scope.dart';
import '../../models/enums.dart';
import '../../theme/akasha_palette.dart';
import '../../theme/akasha_spacing.dart';
import '../../theme/akasha_typography.dart';
import '../../utils/app_l10n.dart';
import '../../widgets/filter_section.dart';

/// Home 중앙 본문 상단 — 검색 진입 + 접이식 필터 (v1 Personal Archive).
class HomeBrowseSearchChrome extends StatefulWidget {
  const HomeBrowseSearchChrome({
    super.key,
    required this.onSearch,
    required this.selectedCategories,
    required this.selectedWorkStatuses,
    required this.selectedMyStatuses,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleWorkStatus,
    required this.onToggleMyStatus,
    required this.selectedEntityScope,
    required this.onEntityScopeChanged,
    this.onAddNewEntity,
    this.compactBreakpoint = 720,
  });

  final VoidCallback onSearch;
  final Set<MediaCategory> selectedCategories;
  final Set<String> selectedWorkStatuses;
  final Set<String> selectedMyStatuses;
  final ValueChanged<MediaCategory> onToggleCategory;
  final VoidCallback onClearCategories;
  final ValueChanged<String> onToggleWorkStatus;
  final ValueChanged<String> onToggleMyStatus;
  final BrowseEntityScope selectedEntityScope;
  final ValueChanged<BrowseEntityScope> onEntityScopeChanged;
  final void Function(EntityAnchorType? type)? onAddNewEntity;
  final double compactBreakpoint;

  static const String searchPlaceholder = '작품, 인물, 시간, 장소, 개념을 검색하세요...';

  static bool hasActiveFilters({
    required Set<MediaCategory> categories,
    required Set<String> workStatuses,
    required Set<String> myStatuses,
    required BrowseEntityScope entityScope,
  }) {
    return categories.isNotEmpty ||
        workStatuses.isNotEmpty ||
        myStatuses.isNotEmpty ||
        entityScope != BrowseEntityScope.all;
  }

  @override
  State<HomeBrowseSearchChrome> createState() => _HomeBrowseSearchChromeState();
}

class _HomeBrowseSearchChromeState extends State<HomeBrowseSearchChrome> {
  var _filtersExpanded = false;

  bool get _hasActiveFilters => HomeBrowseSearchChrome.hasActiveFilters(
    categories: widget.selectedCategories,
    workStatuses: widget.selectedWorkStatuses,
    myStatuses: widget.selectedMyStatuses,
    entityScope: widget.selectedEntityScope,
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < widget.compactBreakpoint;
        return ColoredBox(
          color: palette.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchEntry(
                        onTap: widget.onSearch,
                        showCtrlKHint: !compact,
                      ),
                    ),
                    const SizedBox(width: AkashaSpacing.sm),
                    _FilterToggleButton(
                      expanded: _filtersExpanded,
                      hasActiveFilters: _hasActiveFilters,
                      onPressed: () =>
                          setState(() => _filtersExpanded = !_filtersExpanded),
                    ),
                    if (widget.onAddNewEntity != null) ...[
                      const SizedBox(width: AkashaSpacing.sm),
                      _AddArchiveButton(
                        onTap: () => widget.onAddNewEntity!(
                          widget.selectedEntityScope.catalogEntityType,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_filtersExpanded) ...[
                Divider(height: 1, color: palette.borderSubtle(0.18)),
                FilterSection(
                  selectedCategories: widget.selectedCategories,
                  selectedWorkStatuses: widget.selectedWorkStatuses,
                  selectedMyStatuses: widget.selectedMyStatuses,
                  onToggleCategory: widget.onToggleCategory,
                  onClearCategories: widget.onClearCategories,
                  onToggleWorkStatus: widget.onToggleWorkStatus,
                  onToggleMyStatus: widget.onToggleMyStatus,
                  selectedEntityScope: widget.selectedEntityScope,
                  onEntityScopeChanged: widget.onEntityScopeChanged,
                ),
                Divider(height: 1, color: palette.borderSubtle(0.18)),
              ] else
                Divider(height: 1, color: palette.borderSubtle(0.12)),
            ],
          ),
        );
      },
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap, required this.showCtrlKHint});

  final VoidCallback onTap;
  final bool showCtrlKHint;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final placeholder =
        l10n?.searchPlaceholder ?? HomeBrowseSearchChrome.searchPlaceholder;
    final palette = context.akashaPalette;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AkashaSpacing.md),
        decoration: BoxDecoration(
          color: palette.searchField,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.borderSubtle(0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
            const SizedBox(width: AkashaSpacing.sm),
            Expanded(
              child: Text(
                placeholder,
                style: AkashaTypography.bodySecondary.copyWith(
                  color: palette.textMuted,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showCtrlKHint) ...[
              const SizedBox(width: AkashaSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.hoverSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: palette.borderSubtle(0.24)),
                ),
                child: Text(
                  'Ctrl K',
                  style: AkashaTypography.micro.copyWith(
                    color: palette.textMuted,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.expanded,
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool expanded;
  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final tooltip = expanded
        ? (l10n?.filterCloseTooltip ?? '필터 닫기')
        : (l10n?.filterTooltip ?? '필터');

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Badge(
        isLabelVisible: hasActiveFilters && !expanded,
        smallSize: 8,
        child: Icon(
          expanded ? Icons.filter_list_off : Icons.filter_list,
          size: 20,
          color: hasActiveFilters ? palette.accent : palette.textSecondary,
        ),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      style: IconButton.styleFrom(
        backgroundColor: palette.searchField,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.borderSubtle(0.28)),
        ),
      ),
    );
  }
}

class _AddArchiveButton extends StatelessWidget {
  const _AddArchiveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    return Material(
      color: palette.accentSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: palette.accent),
              const SizedBox(width: 6),
              Text(
                l10n?.filterAddArchive ?? '아카이브',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
