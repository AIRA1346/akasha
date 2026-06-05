import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  섹션 헤더 위젯 (옵시디언 스타일)
// ════════════════════════════════════════════════════════════════

/// 옵시디언 대시보드 스타일의 섹션 구분 헤더.
/// 이모지 아이콘 + 제목 텍스트 + 선택적 부제목으로 구성.
class SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final bool? isExpanded;

  const SectionHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isExpanded != null) ...[
                Icon(
                  isExpanded!
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 20,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
              ],
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
