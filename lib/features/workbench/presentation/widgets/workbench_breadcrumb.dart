import 'package:flutter/material.dart';

import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_typography.dart';

/// 워크벤치 상단 경로 breadcrumb. v1: [FeatureFlags.showWorkbenchBreadcrumb].
class WorkbenchBreadcrumb extends StatelessWidget {
  const WorkbenchBreadcrumb({super.key, required this.segments});

  final List<WorkbenchBreadcrumbSegment> segments;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return Container(
      color: palette.workbenchEditor,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AkashaColors.textCaption,
                ),
              ),
            _SegmentChip(
              segment: segments[i],
              isLast: i == segments.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class WorkbenchBreadcrumbSegment {
  const WorkbenchBreadcrumbSegment({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.segment, required this.isLast});

  final WorkbenchBreadcrumbSegment segment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final style = isLast
        ? AkashaTypography.caption.copyWith(
            color: AkashaColors.textPrimary,
            fontWeight: FontWeight.w600,
          )
        : AkashaTypography.caption.copyWith(color: palette.accent);

    final child = Text(
      segment.label,
      style: style,
      overflow: TextOverflow.ellipsis,
    );

    if (segment.onTap == null || isLast) {
      return Flexible(child: child);
    }

    return Flexible(
      child: InkWell(
        onTap: segment.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: child,
        ),
      ),
    );
  }
}
