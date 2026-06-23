import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';

/// Preview 패널 고정 헤더 — 현재 노드 · 이전 · 기록하기 (R4-C P0).
class PreviewPanelChrome extends StatelessWidget {
  const PreviewPanelChrome({
    super.key,
    required this.typeLabel,
    required this.title,
    required this.onClose,
    required this.onOpenDetail,
    required this.body,
    this.canGoBack = false,
    this.onBack,
  });

  final String typeLabel;
  final String title;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final Widget body;
  final bool canGoBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AkashaColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.grey[500],
                      onPressed: onClose,
                      splashRadius: 20,
                      tooltip: '닫기',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '지금 보는 항목',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (canGoBack && onBack != null) ...[
                      OutlinedButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                        label: const Text(
                          '이전',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          foregroundColor: Colors.grey[300],
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: onOpenDetail,
                        style: FilledButton.styleFrom(
                          backgroundColor: AkashaColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '기록하기',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
