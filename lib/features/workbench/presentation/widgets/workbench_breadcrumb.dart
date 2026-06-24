import 'package:flutter/material.dart';

import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_typography.dart';

/// 워크벤치 상단 경로 breadcrumb. v1: [FeatureFlags.showWorkbenchBreadcrumb].
class WorkbenchBreadcrumb extends StatelessWidget {
  const WorkbenchBreadcrumb({
    super.key,
    required this.segments,
  });

  final List<WorkbenchBreadcrumbSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AkashaColors.workbenchEditor,
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
                  color: Colors.grey[600],
                ),
              ),
            _SegmentChip(segment: segments[i], isLast: i == segments.length - 1),
          ],
        ],
      ),
    );
  }
}

class WorkbenchBreadcrumbSegment {
  const WorkbenchBreadcrumbSegment({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.segment, required this.isLast});

  final WorkbenchBreadcrumbSegment segment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = isLast
        ? AkashaTypography.caption.copyWith(
            color: Colors.grey[200],
            fontWeight: FontWeight.w600,
          )
        : AkashaTypography.caption.copyWith(color: AkashaColors.accent);

    final child = Text(segment.label, style: style, overflow: TextOverflow.ellipsis);

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
