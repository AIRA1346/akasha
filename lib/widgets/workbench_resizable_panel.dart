import 'package:flutter/material.dart';

/// 드래그 리사이즈 + 잠금 토글이 있는 워크벤치 열
class WorkbenchResizablePanel extends StatelessWidget {
  final double width;
  final double minWidth;
  final double maxWidth;
  final bool locked;
  final ValueChanged<double>? onWidthChanged;
  final VoidCallback? onToggleLock;
  final Widget child;

  const WorkbenchResizablePanel({
    super.key,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.locked,
    required this.onWidthChanged,
    required this.onToggleLock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: child,
        ),
        SizedBox(
          width: 6,
          child: MouseRegion(
            cursor: locked
                ? SystemMouseCursors.basic
                : SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: locked || onWidthChanged == null
                  ? null
                  : (details) {
                      onWidthChanged!(width + details.delta.dx);
                    },
              onDoubleTap: onToggleLock,
              child: Container(
                color: const Color(0xFF2D2D44),
                child: Center(
                  child: Icon(
                    locked ? Icons.lock_outline : Icons.drag_indicator,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
