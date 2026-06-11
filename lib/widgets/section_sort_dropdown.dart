import 'package:flutter/material.dart';
import '../utils/helpers.dart';

/// 섹션 헤더용 정렬 드롭다운 (접기/펼치기 제스처 전파 차단)
class SectionSortDropdown extends StatelessWidget {
  final SortCriteria currentCriteria;
  final ValueChanged<SortCriteria> onChanged;
  final List<SortCriteria> options;

  const SectionSortDropdown({
    super.key,
    required this.currentCriteria,
    required this.onChanged,
    this.options = SortCriteria.standardViewCriteria,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        options.contains(currentCriteria) ? currentCriteria : options.first;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SortCriteria>(
            value: effectiveValue,
            isDense: true,
            icon: const Icon(Icons.sort, size: 14, color: Colors.grey),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            dropdownColor: const Color(0xFF2A2A3E),
            items: options
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
