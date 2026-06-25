import 'package:flutter/material.dart';

import '../theme/akasha_colors.dart';

/// Registry-only Work Preview 배너 · 아카이브 CTA (R11 P2).
class WorkPreviewRegistrySurface extends StatelessWidget {
  const WorkPreviewRegistrySurface({
    super.key,
    required this.onArchive,
    this.archiving = false,
  });

  final VoidCallback? onArchive;
  final bool archiving;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141A28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 16, color: AkashaColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사전 작품',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AkashaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '아직 내 볼트에 없습니다. 아카이브하면 연결 그래프에 참여합니다.',
                      style: TextStyle(fontSize: 10, color: AkashaColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: archiving ? null : onArchive,
              icon: archiving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 14),
              label: Text(
                archiving ? '아카이브 중…' : '볼트에 아카이브',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(
                  color: AkashaColors.accent.withValues(alpha: 0.5),
                ),
                foregroundColor: AkashaColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
