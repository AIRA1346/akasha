import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';
import '../../models/personal_library_config.dart';
import 'home_dashboard_controller.dart';

enum SidebarSelectionMode { dashboard, personalLibrary }

/// 나만의 서재 목록·활성 ID·SharedPreferences 영속화
class HomePersonalLibraryController {
  static const _librariesKey = 'akasha_personal_libraries';
  static const _activeIdKey = 'akasha_active_personal_library_id';
  static const _sidebarModeKey = 'akasha_active_sidebar_mode';

  List<PersonalLibraryConfig> libraries = [];
  String? activeLibraryId;
  SidebarSelectionMode sidebarMode = SidebarSelectionMode.dashboard;

  PersonalLibraryConfig? get activeLibrary {
    if (activeLibraryId == null || libraries.isEmpty) return null;
    return libraries.firstWhere(
      (l) => l.id == activeLibraryId,
      orElse: () => libraries.first,
    );
  }

  DashboardFilterSnapshot filterSnapshotFor(PersonalLibraryConfig? library) {
    if (library == null) return const DashboardFilterSnapshot();
    return DashboardFilterSnapshot(
      domain: library.domain,
      categories: Set.from(library.categories),
      workStatuses: Set.from(library.workStatuses),
      myStatuses: Set.from(library.myStatuses),
    );
  }

  DashboardFilterSnapshot get activeFilterSnapshot =>
      filterSnapshotFor(activeLibrary);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_librariesKey);
      final activeId = prefs.getString(_activeIdKey);
      final modeStr = prefs.getString(_sidebarModeKey);

      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as List;
        libraries = decoded
            .map(
              (e) => PersonalLibraryConfig.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        _ensurePresets();
      } else {
        libraries = PersonalLibraryConfig.defaultLibraries();
        await _saveLibrariesInternal(prefs);
      }

      if (activeId != null && libraries.any((l) => l.id == activeId)) {
        activeLibraryId = activeId;
      } else {
        activeLibraryId = 'archive_all';
      }

      sidebarMode = modeStr == SidebarSelectionMode.personalLibrary.name
          ? SidebarSelectionMode.personalLibrary
          : SidebarSelectionMode.dashboard;
    } catch (e) {
      debugPrint('Error loading personal libraries: $e');
      libraries = PersonalLibraryConfig.defaultLibraries();
      activeLibraryId = 'archive_all';
    }
  }

  void _ensurePresets() {
    final existingIds = libraries.map((l) => l.id).toSet();
    for (final preset in PersonalLibraryConfig.defaultLibraries()) {
      if (!existingIds.contains(preset.id)) {
        libraries.add(preset);
      }
    }
    libraries.sort((a, b) {
      final aPreset = a.isPreset;
      final bPreset = b.isPreset;
      if (aPreset != bPreset) return aPreset ? -1 : 1;
      if (aPreset && bPreset) {
        final order = PersonalLibraryConfig.defaultLibraries()
            .map((e) => e.id)
            .toList();
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      }
      return a.name.compareTo(b.name);
    });
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveLibrariesInternal(prefs);
    } catch (e) {
      debugPrint('Error saving personal libraries: $e');
    }
  }

  Future<void> _saveLibrariesInternal(SharedPreferences prefs) async {
    final encoded = jsonEncode(libraries.map((e) => e.toJson()).toList());
    await prefs.setString(_librariesKey, encoded);
  }

  Future<void> saveActiveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (activeLibraryId != null) {
        await prefs.setString(_activeIdKey, activeLibraryId!);
      }
      await prefs.setString(_sidebarModeKey, sidebarMode.name);
    } catch (e) {
      debugPrint('Error saving personal library active state: $e');
    }
  }

  void selectPersonal(String id) {
    activeLibraryId = id;
    sidebarMode = SidebarSelectionMode.personalLibrary;
    saveActiveState();
  }

  void selectDashboardMode() {
    sidebarMode = SidebarSelectionMode.dashboard;
    saveActiveState();
  }

  void add(PersonalLibraryConfig config) {
    libraries.add(config);
    selectPersonal(config.id);
  }

  bool remove(String id) {
    if (PersonalLibraryConfig.presetIds.contains(id)) return false;
    libraries.removeWhere((l) => l.id == id);
    if (activeLibraryId == id) {
      activeLibraryId = 'archive_all';
      sidebarMode = SidebarSelectionMode.personalLibrary;
    }
    return true;
  }

  void syncActiveFromFilters({
    required AppDomain? domain,
    required Set<MediaCategory> categories,
    required Set<String> workStatuses,
    required Set<String> myStatuses,
  }) {
    final active = activeLibrary;
    if (active == null) return;
    active.domain = domain;
    active.categories = Set.from(categories);
    active.workStatuses = Set.from(workStatuses);
    active.myStatuses = Set.from(myStatuses);
  }
}
