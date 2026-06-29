import 'package:flutter/material.dart';

import '../theme/akasha_colors.dart';
import '../theme/akasha_typography.dart';

class PosterCardLibraryCountBadge extends StatelessWidget {
  const PosterCardLibraryCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AkashaColors.libraryCountBadgeAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        '★$count',
        style: AkashaTypography.posterLibraryBadge,
      ),
    );
  }
}

class PosterCardArchivedBadge extends StatelessWidget {
  const PosterCardArchivedBadge({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sanctum vault 연동됨',
      child: Semantics(
        label: '아카이브됨',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: AkashaColors.posterArchivedBadge,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.description_outlined,
            size: size * 0.58,
            color: AkashaColors.posterArchivedBadge,
          ),
        ),
      ),
    );
  }
}

class PosterCardMetaPill extends StatelessWidget {
  const PosterCardMetaPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AkashaTypography.posterMetaPill.copyWith(color: foreground),
      ),
    );
  }
}
