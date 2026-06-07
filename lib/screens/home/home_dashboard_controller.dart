import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dashboard_config.dart';
import '../../models/enums.dart';

/// 활성 대시보드에서 복원할 필터 스냅샷
class DashboardFilterSnapshot {
  final AppDomain? domain;
  final Set<MediaCategory> categories;
  final Set<String> workStatuses;
  final Set<String> myStatuses;

  const DashboardFilterSnapshot({
    this.domain,
    this.categories = const {},
    this.workStatuses = const {},
    this.myStatuses = const {},
  });
}

/// 대시보드 목록·활성 ID·SharedPreferences 영속화
class HomeDashboardController {
  static const _dashboardsKey = 'akasha_dashboards';
  static const _activeIdKey = 'akasha_active_dashboard_id';

  List<DashboardConfig> dashboards = [];
  String? activeDashboardId;

  DashboardConfig? get activeDashboard {
    if (activeDashboardId == null || dashboards.isEmpty) return null;
    return dashboards.firstWhere(
      (d) => d.id == activeDashboardId,
      orElse: () => dashboards.first,
    );
  }

  DashboardFilterSnapshot filterSnapshotFor(DashboardConfig? dashboard) {
    if (dashboard == null) return const DashboardFilterSnapshot();
    return DashboardFilterSnapshot(
      domain: dashboard.domain,
      categories: Set.from(dashboard.categories),
      workStatuses: Set.from(dashboard.workStatuses),
      myStatuses: Set.from(dashboard.myStatuses),
    );
  }

  DashboardFilterSnapshot get activeFilterSnapshot =>
      filterSnapshotFor(activeDashboard);

  static List<DashboardConfig> defaultDashboards() => [
        DashboardConfig(
          id: 'master_index',
          name: 'master_index',
          domain: null,
          categories: {},
        ),
        DashboardConfig(
          id: 'manga_dashboard',
          name: 'manga_dashboard',
          domain: AppDomain.subculture,
          categories: {MediaCategory.manga},
        ),
        DashboardConfig(
          id: 'game_dashboard',
          name: 'game_dashboard',
          domain: null,
          categories: {MediaCategory.game},
        ),
      ];

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dashJsonStr = prefs.getString(_dashboardsKey);
      final activeId = prefs.getString(_activeIdKey);

      if (dashJsonStr != null) {
        final decoded = jsonDecode(dashJsonStr) as List;
        dashboards = decoded
            .map((e) => DashboardConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        dashboards = defaultDashboards();
        await _saveDashboardsInternal(prefs);
      }

      if (activeId != null && dashboards.any((d) => d.id == activeId)) {
        activeDashboardId = activeId;
      } else {
        activeDashboardId = dashboards.first.id;
      }
    } catch (e) {
      debugPrint('Error loading dashboards: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveDashboardsInternal(prefs);
    } catch (e) {
      debugPrint('Error saving dashboards: $e');
    }
  }

  Future<void> _saveDashboardsInternal(SharedPreferences prefs) async {
    final encoded = jsonEncode(dashboards.map((e) => e.toJson()).toList());
    await prefs.setString(_dashboardsKey, encoded);
  }

  Future<void> saveActiveId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeIdKey, id);
    } catch (e) {
      debugPrint('Error saving active dashboard ID: $e');
    }
  }

  void select(String id) {
    activeDashboardId = id;
    saveActiveId(id);
  }

  void add(DashboardConfig config) {
    dashboards.add(config);
    select(config.id);
  }

  bool remove(String id) {
    if (id == 'master_index') return false;
    dashboards.removeWhere((d) => d.id == id);
    if (activeDashboardId == id) {
      select('master_index');
    }
    return true;
  }

  void syncActiveFromFilters({
    required AppDomain? domain,
    required Set<MediaCategory> categories,
    required Set<String> workStatuses,
    required Set<String> myStatuses,
  }) {
    final active = activeDashboard;
    if (active == null) return;
    active.domain = domain;
    active.categories = Set.from(categories);
    active.workStatuses = Set.from(workStatuses);
    active.myStatuses = Set.from(myStatuses);
  }
}
