import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

/// Preview 패널 고정 헤더 — 현재 노드 · 이전 · 기록하기 (R4-C P0).
class PreviewPanelChrome extends StatelessWidget {
  const PreviewPanelChrome({
    super.key,
    required this.typeLabel,
    required this.onClose,
    required this.body,
    this.title,
    this.onOpenDetail,
    this.compactHeader = false,
    this.canGoBack = false,
    this.onBack,
  });

  final String typeLabel;
  final String? title;
  final VoidCallback onClose;
  final VoidCallback? onOpenDetail;
  final Widget body;
  final bool compactHeader;
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
              bottom: BorderSide(color: AkashaColors.borderSubtle(0.08)),
            ),
          ),
          child: Padding(
            padding: compactHeader
                ? AkashaSpacing.previewPanelHeaderCompact
                : AkashaSpacing.previewPanelHeader,
            child: compactHeader
                ? _buildCompactHeader()
                : _buildLegacyHeader(),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AkashaSpacing.sm,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AkashaColors.accent.withValues(alpha: 0.12),
            borderRadius: AkashaRadius.smBorder,
          ),
          child: Text(
            typeLabel,
            style: AkashaTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AkashaColors.textMuted,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AkashaColors.textCaption,
          onPressed: onClose,
          splashRadius: 20,
          tooltip: '닫기',
        ),
      ],
    );
  }

  Widget _buildLegacyHeader() {
    final detailTitle = title ?? '';
    final openDetail = onOpenDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AkashaSpacing.xs + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AkashaColors.accent.withValues(alpha: 0.12),
                borderRadius: AkashaRadius.smBorder,
              ),
              child: Text(
                typeLabel,
                style: AkashaTypography.micro.copyWith(
                  color: AkashaColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AkashaColors.textCaption,
              onPressed: onClose,
              splashRadius: 20,
              tooltip: '닫기',
            ),
          ],
        ),
        SizedBox(height: AkashaSpacing.xs + 2),
        Text('지금 보는 항목', style: AkashaTypography.micro),
        const SizedBox(height: 2),
        Text(
          detailTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AkashaTypography.dashboardSectionTitle,
        ),
        if (openDetail != null) ...[
          SizedBox(height: AkashaSpacing.sm + 2),
          Row(
            children: [
              if (canGoBack && onBack != null) ...[
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 14),
                  label: Text('이전', style: AkashaTypography.compactLabel),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AkashaSpacing.sm,
                    ),
                    foregroundColor: AkashaColors.textSecondary,
                    side: BorderSide(color: AkashaColors.borderSubtle(0.12)),
                  ),
                ),
                SizedBox(width: AkashaSpacing.sm),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: openDetail,
                  style: FilledButton.styleFrom(
                    backgroundColor: AkashaColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AkashaRadius.mdBorder,
                    ),
                  ),
                  child: Text('기록하기', style: AkashaTypography.buttonLabel),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
