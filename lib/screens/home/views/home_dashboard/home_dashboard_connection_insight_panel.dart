import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';
import 'home_dashboard_lower_panel.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardConnectionInsightPanel extends StatelessWidget {
  const HomeDashboardConnectionInsightPanel({
    super.key,
    required this.panelKey,
    required this.future,
    required this.onOpenGraph,
  });

  final Key panelKey;
  final Future<RecordLinkSummary> future;
  final VoidCallback onOpenGraph;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return HomeDashboardLowerPanel(
      panelKey: panelKey,
      child: FutureBuilder<RecordLinkSummary>(
        future: future,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          final countLabel = summary == null || summary.isEmpty
              ? null
              : (l10n?.dashboardConnectionCount(summary.totalLinkCount) ??
                    '${summary.totalLinkCount}개의 연결');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeDashboardStyles.sectionHeader(
                context,
                l10n?.dashboardConnectionInsightTitle ?? '연결 인사이트',
                countLabel: countLabel,
              ),
              const SizedBox(height: AkashaSpacing.md),
              if (snapshot.connectionState == ConnectionState.waiting)
                const HomeDashboardPanelLoading()
              else if (snapshot.hasError)
                HomeDashboardPanelStatus(
                  icon: Icons.sync_problem_outlined,
                  message:
                      l10n?.dashboardConnectionError ?? '연결 요약을 잠시 불러올 수 없습니다.',
                  actionLabel: l10n?.dashboardExploreGraph ?? '그래프 탐색',
                  onAction: onOpenGraph,
                )
              else if (summary == null || summary.isEmpty)
                HomeDashboardPanelStatus(
                  icon: Icons.hub_outlined,
                  message:
                      l10n?.dashboardConnectionEmpty ?? '아직 저장된 기록 연결이 없습니다.',
                  actionLabel: l10n?.dashboardExploreGraph ?? '그래프 탐색',
                  onAction: onOpenGraph,
                )
              else ...[
                _ConnectionMapVisual(palette: palette),
                const SizedBox(height: AkashaSpacing.sm),
                Text(
                  l10n?.dashboardConnectionCount(summary.totalLinkCount) ??
                      '${summary.totalLinkCount}개의 연결',
                  style: AkashaTypography.dashboardPanelTitle.copyWith(
                    color: palette.textPrimary,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AkashaSpacing.xs),
                Text(
                  l10n?.dashboardConnectionDescription ??
                      '아카이브 기록 사이에 실제로 저장된 연결입니다.',
                  style: AkashaTypography.micro.copyWith(
                    color: palette.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AkashaSpacing.md),
                Wrap(
                  spacing: AkashaSpacing.sm,
                  runSpacing: AkashaSpacing.sm,
                  children: [
                    _InsightFact(
                      icon: Icons.description_outlined,
                      label:
                          l10n?.dashboardLinkedRecordsCount(
                            summary.linkedRecordCount,
                          ) ??
                          '연결된 기록 ${summary.linkedRecordCount}개',
                      palette: palette,
                    ),
                    _InsightFact(
                      icon: Icons.category_outlined,
                      label:
                          l10n?.dashboardConnectedEntitiesCount(
                            summary.connectedEntityCount,
                          ) ??
                          '연결된 엔티티 ${summary.connectedEntityCount}개',
                      palette: palette,
                    ),
                  ],
                ),
                const SizedBox(height: AkashaSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: onOpenGraph,
                    icon: const Icon(Icons.hub_outlined, size: 17),
                    label: Text(l10n?.dashboardExploreGraph ?? '그래프 탐색'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InsightFact extends StatelessWidget {
  const _InsightFact({
    required this.icon,
    required this.label,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: AkashaRadius.mdBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.accent, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: AkashaTypography.micro.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionMapVisual extends StatelessWidget {
  const _ConnectionMapVisual({required this.palette});

  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 62,
        child: CustomPaint(
          painter: _ConnectionMapPainter(
            lineColor: palette.borderSubtle(0.62),
            nodeColor: palette.accent,
            glowColor: palette.accentSoft,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConnectionMapPainter extends CustomPainter {
  const _ConnectionMapPainter({
    required this.lineColor,
    required this.nodeColor,
    required this.glowColor,
  });

  final Color lineColor;
  final Color nodeColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.08, size.height * 0.65),
      Offset(size.width * 0.28, size.height * 0.28),
      Offset(size.width * 0.5, size.height * 0.58),
      Offset(size.width * 0.72, size.height * 0.2),
      Offset(size.width * 0.92, size.height * 0.56),
    ];
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;
    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], linePaint);
    }
    canvas.drawLine(points[1], points[3], linePaint);
    canvas.drawLine(points[0], points[2], linePaint);

    final glowPaint = Paint()..color = glowColor;
    final nodePaint = Paint()..color = nodeColor;
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], index == 2 ? 10 : 7, glowPaint);
      canvas.drawCircle(points[index], index == 2 ? 4 : 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionMapPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.glowColor != glowColor;
  }
}
