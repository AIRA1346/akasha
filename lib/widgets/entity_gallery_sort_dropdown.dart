import 'package:flutter/material.dart';

import '../models/entity_gallery_sort.dart';
import '../theme/akasha_colors.dart';
import '../theme/akasha_palette.dart';

/// Entity gallery header sort control.
class EntityGallerySortDropdown extends StatelessWidget {
  const EntityGallerySortDropdown({
    super.key,
    required this.currentCriteria,
    required this.onChanged,
    this.options = EntityGallerySortCriteria.galleryOptions,
  });

  final EntityGallerySortCriteria currentCriteria;
  final ValueChanged<EntityGallerySortCriteria> onChanged;
  final List<EntityGallerySortCriteria> options;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final effectiveValue = options.contains(currentCriteria)
        ? currentCriteria
        : options.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: palette.hoverSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EntityGallerySortCriteria>(
          value: effectiveValue,
          isDense: true,
          icon: const Icon(Icons.sort, size: 14, color: AkashaColors.textMuted),
          style: const TextStyle(fontSize: 11, color: AkashaColors.textMuted),
          dropdownColor: palette.workbenchTile,
          items: options
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.label, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
