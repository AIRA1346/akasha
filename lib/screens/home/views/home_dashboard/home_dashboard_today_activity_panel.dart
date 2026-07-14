import 'package:flutter/material.dart';

import '../../../../core/archiving/record_kind.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/app_l10n.dart';
import 'home_dashboard_insight_loader.dart';
import 'home_dashboard_lower_panel.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardTodayActivityPanel extends StatelessWidget {
  const HomeDashboardTodayActivityPanel({
    super.key,
    required this.panelKey,
    required this.future,
  });

  final Key panelKey;
  final Future<HomeArchiveActivityData> future;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);

    return HomeDashboardLowerPanel(
      panelKey: panelKey,
      child: FutureBuilder<HomeArchiveActivityData>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final countLabel = data == null || data.todayCount == 0
              ? null
              : (l10n?.dashboardTodayCount(data.todayCount) ??
                    '변경 ${data.todayCount}개');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeDashboardStyles.sectionHeader(
                context,
                l10n?.dashboardTodayTitle ?? '오늘의 기록',
                countLabel: countLabel,
              ),
              const SizedBox(height: AkashaSpacing.md),
              if (snapshot.connectionState == ConnectionState.waiting)
                const HomeDashboardPanelLoading()
              else if (snapshot.hasError)
                HomeDashboardPanelStatus(
                  icon: Icons.event_busy_outlined,
                  message:
                      l10n?.dashboardTodayError ?? '오늘의 기록 활동을 잠시 불러올 수 없습니다.',
                )
              else if (data == null || !data.vaultAvailable)
                HomeDashboardPanelStatus(
                  icon: Icons.folder_off_outlined,
                  message:
                      l10n?.dashboardTodayUnavailable ??
                      '볼트를 연결하면 오늘의 기록 활동을 볼 수 있습니다.',
                )
              else if (data.items.isEmpty)
                HomeDashboardPanelStatus(
                  icon: Icons.event_available_outlined,
                  message:
                      l10n?.dashboardTodayEmpty ?? '오늘 추가되거나 수정된 기록이 없습니다.',
                )
              else
                for (var index = 0; index < data.items.length; index++) ...[
                  if (index > 0) const Divider(height: AkashaSpacing.md),
                  _ActivityRow(activity: data.items[index]),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final HomeArchiveActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(activity.occurredAt.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final activityLabel = activity.kind == HomeArchiveActivityKind.updated
        ? (l10n?.dashboardActivityUpdated ?? '기록 수정')
        : (l10n?.dashboardActivityAdded ?? '새 기록 추가');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: AkashaRadius.mdBorder,
          ),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              _recordKindIcon(activity.recordKind),
              color: palette.accent,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: AkashaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AkashaTypography.buttonLabel.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$activityLabel · ${_recordKindLabel(activity.recordKind, l10n)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AkashaTypography.micro.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AkashaSpacing.sm),
        Text(
          time,
          style: AkashaTypography.micro.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }

  static IconData _recordKindIcon(RecordKind kind) => switch (kind) {
    RecordKind.workJournal => Icons.menu_book_outlined,
    RecordKind.entityJournal => Icons.person_outline_rounded,
    RecordKind.freeformJournal => Icons.edit_note_rounded,
    RecordKind.timelineEntry => Icons.timeline_outlined,
  };

  static String _recordKindLabel(RecordKind kind, AppLocalizations? l10n) {
    return switch (kind) {
      RecordKind.workJournal => l10n?.recordKindWorkJournal ?? '작품 저널',
      RecordKind.entityJournal => l10n?.recordKindEntityJournal ?? '엔티티 저널',
      RecordKind.freeformJournal => l10n?.recordKindFreeformJournal ?? '자유 저널',
      RecordKind.timelineEntry => l10n?.recordKindTimeline ?? '타임라인',
    };
  }
}
