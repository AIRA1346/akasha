part of 'browse_dashboard_sections.dart';

List<Widget> _buildYearlySlivers(
  BuildContext context,
  BrowseDashboardSections section,
  BrowseGridMetrics metrics,
) {
  final l10n = lookupAppL10n(context);
  final groups = section.yearGroups!;
  final slivers = <Widget>[
    SliverToBoxAdapter(
      child: _sectionHeader(
        emoji: '🗓️',
        title:
            l10n?.yearlyLibraryTitle ??
            '연도별 라이브러리 (Yearly Chronological Library)',
        titleColor: const Color(0xFFF09819),
        subtitle:
            l10n?.yearlyLibraryDescription ?? '출시 연도별로 크로놀로지컬하게 정렬된 라이브러리입니다.',
        expanded: section.yearlyExpanded,
        onExpandedChanged: section.onYearlyExpandedChanged!,
        sortCriteria: section.yearlySortCriteria,
        onSortChanged: section.onYearlySortChanged!,
      ),
    ),
  ];

  if (section.yearlyExpanded) {
    for (final year in groups.sortedYears) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  l10n != null ? l10n.yearlyHeader(year) : '🗓️ $year년',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n != null
                      ? l10n.worksCountSuffix(groups.byYear[year]!.length)
                      : '(${groups.byYear[year]!.length}개 작품)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AkashaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      slivers.addAll(_cardGridSlivers(section, groups.byYear[year]!, metrics));
    }
    if (groups.noYear.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  l10n?.yearlyNoYear ?? '🗓️ 연도 미지정',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n != null
                      ? l10n.worksCountSuffix(groups.noYear.length)
                      : '(${groups.noYear.length}개 작품)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AkashaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      slivers.addAll(_cardGridSlivers(section, groups.noYear, metrics));
    }
  }
  slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
  return slivers;
}
