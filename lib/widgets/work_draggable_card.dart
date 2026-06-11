import 'package:flutter/material.dart';

import '../models/work_drag_payload.dart';

/// DnD-A — ⠿ 핸들로만 드래그 시작 (카드 탭은 상세 열기 유지)
class WorkDraggableCard extends StatefulWidget {
  final WorkDragPayload payload;
  final Widget child;
  final bool enabled;
  final VoidCallback? onDragStarted;

  const WorkDraggableCard({
    super.key,
    required this.payload,
    required this.child,
    this.enabled = true,
    this.onDragStarted,
  });

  @override
  State<WorkDraggableCard> createState() => _WorkDraggableCardState();
}

class _WorkDraggableCardState extends State<WorkDraggableCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_hovered)
            Positioned(
              top: 6,
              right: 6,
              child: Draggable<WorkDragPayload>(
                data: widget.payload,
                onDragStarted: widget.onDragStarted,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.9,
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        widget.payload.item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
