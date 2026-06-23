import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';

/// 프리뷰 하단 빠른 메모 진입 (mock · R15).
class PreviewMemoBar extends StatelessWidget {
  const PreviewMemoBar({
    super.key,
    required this.onOpenDetail,
  });

  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onOpenDetail,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    '메모 추가…',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onOpenDetail,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: AkashaColors.accent,
              tooltip: '기록하기',
            ),
          ],
        ),
      ),
    );
  }
}
