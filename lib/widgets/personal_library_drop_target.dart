import 'package:flutter/material.dart';

import '../models/work_drag_payload.dart';

/// 사이드바 curated 서재 행 — DnD-A drop zone
class PersonalLibraryDropTarget extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final void Function(WorkDragPayload payload) onAccept;

  const PersonalLibraryDropTarget({
    super.key,
    required this.child,
    required this.accentColor,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<WorkDragPayload>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: hovering
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            border: hovering
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.55),
                    width: 1.2,
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
