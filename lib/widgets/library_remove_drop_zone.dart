import 'package:flutter/material.dart';

import '../models/work_drag_payload.dart';

/// DnD-C — 카드를 끌어다 놓으면 활성 curated 서재에서 제거 (md 유지)
class LibraryRemoveDropZone extends StatelessWidget {
  final void Function(WorkDragPayload payload) onRemove;
  final bool compact;

  const LibraryRemoveDropZone({
    super.key,
    required this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, compact ? 8 : 16),
      child: DragTarget<WorkDragPayload>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => onRemove(details.data),
        builder: (context, candidate, rejected) {
          final active = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: active
                  ? Colors.redAccent.withValues(alpha: 0.18)
                  : const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? Colors.redAccent.withValues(alpha: 0.7)
                    : Colors.redAccent.withValues(alpha: 0.25),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: compact ? 18 : 20,
                  color: active ? Colors.redAccent : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  '서재에서 제거 (볼트 기록은 유지)',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: active ? Colors.redAccent : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
