part of 'browse_dashboard_sections.dart';

Widget _sectionHeader({
  required String emoji,
  required String title,
  required Color titleColor,
  String? subtitle,
  required bool expanded,
  required ValueChanged<bool> onExpandedChanged,
  required SortCriteria sortCriteria,
  required ValueChanged<SortCriteria> onSortChanged,
  List<SortCriteria> sortOptions = SortCriteria.standardViewCriteria,
}) {
  return GestureDetector(
    onTap: () => onExpandedChanged(!expanded),
    child: SectionHeader(
      emoji: emoji,
      title: title,
      titleColor: titleColor,
      subtitle: subtitle,
      isExpanded: expanded,
      trailing: SectionSortDropdown(
        currentCriteria: sortOptions.contains(sortCriteria)
            ? sortCriteria
            : sortOptions.first,
        onChanged: onSortChanged,
        options: sortOptions,
      ),
    ),
  );
}
