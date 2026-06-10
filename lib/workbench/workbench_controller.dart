import 'package:flutter/foundation.dart';

import '../models/akasha_item.dart';
import 'work_tab.dart';
import 'workbench_layout_prefs.dart';

/// 열린 작품 탭·활성 탭·레이아웃 prefs
class WorkbenchController extends ChangeNotifier {
  static const int maxTabs = 16;

  final List<WorkTab> tabs = [];
  String? activeTabId;
  WorkbenchLayoutPrefs layout = WorkbenchLayoutPrefs.defaults();
  bool _prefsLoaded = false;

  bool get prefsLoaded => _prefsLoaded;
  bool get hasOpenWork => activeTabId != null && activeTab != null;
  bool get hasTabs => tabs.isNotEmpty;

  WorkTab? get activeTab {
    if (activeTabId == null) return null;
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }

  Future<void> loadPrefs() async {
    await layout.load();
    _prefsLoaded = true;
    notifyListeners();
  }

  void openWork(AkashaItem item) {
    final id = WorkTab.idFor(item);
    final existing = tabs.where((t) => t.id == id).firstOrNull;
    if (existing != null) {
      existing.item = item;
      activeTabId = id;
    } else {
      if (tabs.length >= maxTabs) {
        tabs.removeAt(0);
      }
      tabs.add(WorkTab(id: id, item: item));
      activeTabId = id;
    }
    layout.tabRailCollapsed = false;
    notifyListeners();
  }

  void selectTab(String id) {
    if (tabs.any((t) => t.id == id)) {
      activeTabId = id;
      notifyListeners();
    }
  }

  void closeTab(String id) {
    tabs.removeWhere((t) => t.id == id);
    if (activeTabId == id) {
      activeTabId = tabs.isEmpty ? null : tabs.last.id;
    }
    notifyListeners();
  }

  void markDirty(String id, {bool dirty = true}) {
    for (final tab in tabs) {
      if (tab.id == id) {
        tab.isDirty = dirty;
        notifyListeners();
        return;
      }
    }
  }

  void updateTabItem(String id, AkashaItem item, {bool dirty = false}) {
    for (final tab in tabs) {
      if (tab.id == id) {
        tab.item = item;
        tab.isDirty = dirty;
        notifyListeners();
        return;
      }
    }
  }

  void toggleTabRailCollapsed() {
    layout.tabRailCollapsed = !layout.tabRailCollapsed;
    layout.save();
    notifyListeners();
  }

  void setTabRailWidth(double width) {
    layout.tabRailWidth = width.clamp(120, 320);
    layout.save();
    notifyListeners();
  }

  void setInfoPanelWidth(double width) {
    layout.infoPanelWidth = width.clamp(240, 480);
    layout.save();
    notifyListeners();
  }

  void toggleTabRailLocked() {
    layout.tabRailLocked = !layout.tabRailLocked;
    layout.save();
    notifyListeners();
  }

  void toggleInfoPanelLocked() {
    layout.infoPanelLocked = !layout.infoPanelLocked;
    layout.save();
    notifyListeners();
  }
}
