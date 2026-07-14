import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../services/record_summary_index_service.dart';
import '../../../../theme/akasha_spacing.dart';
import 'home_dashboard_connection_insight_panel.dart';
import 'home_dashboard_insight_loader.dart';
import 'home_dashboard_quick_actions_section.dart';
import 'home_dashboard_today_activity_panel.dart';

class HomeDashboardLowerSection extends StatefulWidget {
  const HomeDashboardLowerSection({
    super.key,
    required this.linkIndex,
    required this.linkIndexRevision,
    required this.vaultPath,
    required this.onSearch,
    required this.onExploreEntities,
    required this.onGoExplore,
    required this.onGoKnowledgeGraph,
    required this.onTimeline,
    this.recordIndex,
    this.now,
  });

  static const layoutKey = ValueKey('home-dashboard-lower-layout');
  static const connectionPanelKey = ValueKey('home-dashboard-connection-panel');
  static const activityPanelKey = ValueKey('home-dashboard-activity-panel');

  final RecordLinkPort linkIndex;
  final int linkIndexRevision;
  final String? vaultPath;
  final VoidCallback onSearch;
  final VoidCallback onExploreEntities;
  final VoidCallback onGoExplore;
  final VoidCallback onGoKnowledgeGraph;
  final VoidCallback onTimeline;
  final RecordSummaryIndexService? recordIndex;
  final DateTime? now;

  @override
  State<HomeDashboardLowerSection> createState() =>
      _HomeDashboardLowerSectionState();
}

class _HomeDashboardLowerSectionState extends State<HomeDashboardLowerSection> {
  late RecordSummaryIndexService _recordIndex;
  late Future<RecordLinkSummary> _connectionFuture;
  late Future<HomeArchiveActivityData> _activityFuture;

  @override
  void initState() {
    super.initState();
    _recordIndex = widget.recordIndex ?? RecordSummaryIndexService();
    _reloadAll();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardLowerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordIndex != widget.recordIndex) {
      _recordIndex = widget.recordIndex ?? RecordSummaryIndexService();
    }
    if (oldWidget.linkIndex != widget.linkIndex ||
        oldWidget.linkIndexRevision != widget.linkIndexRevision ||
        oldWidget.vaultPath != widget.vaultPath) {
      _connectionFuture = widget.linkIndex.loadSummary();
    }
    if (oldWidget.vaultPath != widget.vaultPath ||
        oldWidget.linkIndexRevision != widget.linkIndexRevision ||
        oldWidget.recordIndex != widget.recordIndex ||
        oldWidget.now != widget.now) {
      _activityFuture = _loadActivity();
    }
  }

  void _reloadAll() {
    _connectionFuture = widget.linkIndex.loadSummary();
    _activityFuture = _loadActivity();
  }

  Future<HomeArchiveActivityData> _loadActivity() {
    return loadHomeArchiveActivity(
      vaultPath: widget.vaultPath,
      recordIndex: _recordIndex,
      now: widget.now ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickActions = HomeDashboardQuickActionsSection(
      onSearch: widget.onSearch,
      onExploreEntities: widget.onExploreEntities,
      onGoExplore: widget.onGoExplore,
      onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
      onTimeline: widget.onTimeline,
    );
    final connection = HomeDashboardConnectionInsightPanel(
      panelKey: HomeDashboardLowerSection.connectionPanelKey,
      future: _connectionFuture,
      onOpenGraph: widget.onGoKnowledgeGraph,
    );
    final activity = HomeDashboardTodayActivityPanel(
      panelKey: HomeDashboardLowerSection.activityPanelKey,
      future: _activityFuture,
    );

    return LayoutBuilder(
      key: HomeDashboardLowerSection.layoutKey,
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1120) {
          return SizedBox(
            height: 320,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: quickActions),
                const SizedBox(width: AkashaSpacing.lg),
                Expanded(child: connection),
                const SizedBox(width: AkashaSpacing.lg),
                Expanded(child: activity),
              ],
            ),
          );
        }
        if (constraints.maxWidth >= 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              quickActions,
              const SizedBox(height: AkashaSpacing.lg),
              SizedBox(
                height: 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: connection),
                    const SizedBox(width: AkashaSpacing.lg),
                    Expanded(child: activity),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            quickActions,
            const SizedBox(height: AkashaSpacing.lg),
            connection,
            const SizedBox(height: AkashaSpacing.lg),
            activity,
          ],
        );
      },
    );
  }
}
