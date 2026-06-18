import 'package:flutter/foundation.dart';

import '../../../models/akasha_item.dart';
import '../presentation/work_tab.dart';
import 'workbench_layout_prefs.dart';

/// 열린 작품 탭·활성 탭·레이아웃 prefs
class WorkbenchController extends ChangeNotifier {
  static const int maxTabs = 16;

  final List<WorkTab> tabs = [];
  String? activeTabId;
  WorkbenchLayoutPrefs layout = WorkbenchLayoutPrefs.defaults();
  bool _prefsLoaded = false;
  bool _workViewVisible = false;

  /// 활성 작품 탭의 md 저장 (Ctrl+S·탭 닫기 시 사용).
  Future<void> Function()? saveActiveTab;

  bool get prefsLoaded => _prefsLoaded;
  /// 작품 상세(3·4열)가 메인에 표시 중인지
  bool get hasOpenWork => _workViewVisible && activeTabId != null && activeTab != null;
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
    _workViewVisible = true;
    notifyListeners();
  }

  /// 서재·대시보드 탐색으로 돌아갈 때 — 탭은 유지, 작품 상세 패널만 숨김
  void showBrowse() {
    if (!_workViewVisible) return;
    _workViewVisible = false;
    notifyListeners();
  }

  void selectTab(String id) {
    if (tabs.any((t) => t.id == id)) {
      activeTabId = id;
      _workViewVisible = true;
      notifyListeners();
    }
  }

  void closeTab(String id) {
    tabs.removeWhere((t) => t.id == id);
    if (activeTabId == id) {
      activeTabId = tabs.isEmpty ? null : tabs.last.id;
      if (tabs.isEmpty) _workViewVisible = false;
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

  /// 볼트 재로드 후 디스크 내용을 열린 탭에 반영 (편집 중 탭은 유지).
  void syncFromVaultItems(List<AkashaItem> vaultItems) {
    var changed = false;
    for (final tab in tabs) {
      if (tab.isDirty) continue;
      final match = _matchVaultItem(tab.item, vaultItems);
      if (match == null) continue;
      if (_sameItemSnapshot(tab.item, match)) continue;
      tab.item = match;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  static AkashaItem? _matchVaultItem(
    AkashaItem tabItem,
    List<AkashaItem> vaultItems,
  ) {
    final path = tabItem.filePath;
    if (path != null && path.isNotEmpty) {
      for (final item in vaultItems) {
        if (item.filePath == path) return item;
      }
    }
    if (tabItem.workId.isNotEmpty) {
      for (final item in vaultItems) {
        if (item.workId == tabItem.workId) return item;
      }
    }
    for (final item in vaultItems) {
      if (item.title == tabItem.title && item.category == tabItem.category) {
        return item;
      }
    }
    return null;
  }

  static bool _sameItemSnapshot(AkashaItem a, AkashaItem b) {
    return a.workId == b.workId &&
        a.title == b.title &&
        a.rating == b.rating &&
        a.posterPath == b.posterPath &&
        a.bodyRaw == b.bodyRaw &&
        a.description == b.description &&
        a.review == b.review &&
        a.myStatusLabel == b.myStatusLabel &&
        a.workStatusLabel == b.workStatusLabel &&
        a.isHallOfFame == b.isHallOfFame;
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
    layout.infoPanelWidth = width.clamp(220, 400);
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
