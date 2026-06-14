import 'package:flutter/material.dart';

import '../../models/dashboard_config.dart';
import 'coordinators/home_filter_coordinator.dart';
import 'dialogs/delete_dashboard_confirm_dialog.dart';
import 'dialogs/dashboard_edit_dialog.dart';
import 'home_dashboard_controller.dart';

/// 대시보드 편집·삭제 Presentation glue.
class HomeDashboardUi {
  const HomeDashboardUi({
    required this.dashboardCtrl,
    required this.filterCoordinator,
  });

  final HomeDashboardController dashboardCtrl;
  final HomeFilterCoordinator filterCoordinator;

  Future<void> confirmDelete(
    BuildContext context, {
    required String id,
    required void Function(void Function()) setState,
  }) async {
    if (id == 'master_index') return;
    final confirmed = await showDeleteDashboardConfirmDialog(context);
    if (confirmed != true || !context.mounted) return;
    setState(() {
      dashboardCtrl.remove(id);
      filterCoordinator.applyDashboardFilters(
        dashboardCtrl.activeFilterSnapshot,
      );
    });
    await dashboardCtrl.save();
  }

  Future<void> showEditDialog(
    BuildContext context, {
    required DashboardConfig? config,
    required void Function(void Function()) setState,
  }) async {
    await showDashboardEditDialog(
      context,
      config: config,
      onSaved: (dashboard, isNew) {
        setState(() {
          if (isNew) {
            dashboardCtrl.add(dashboard);
          } else if (dashboardCtrl.activeDashboardId == dashboard.id) {
            filterCoordinator.applyDashboardFilters(
              dashboardCtrl.filterSnapshotFor(dashboard),
            );
          }
        });
        dashboardCtrl.save();
      },
    );
  }
}
