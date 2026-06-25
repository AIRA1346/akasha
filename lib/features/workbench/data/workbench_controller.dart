import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/entity_journal_parser.dart';
import '../presentation/collectible_tab.dart';
import 'workbench_layout_prefs.dart';

/// 열린 Collectible 세션·레이아웃 prefs (Phase 6: Work + Entity).
class WorkbenchController extends ChangeNotifier {
  static const int maxTabs = 1;

  final List<CollectibleTab> tabs = [];
  String? activeTabId;
  WorkbenchLayoutPrefs layout = WorkbenchLayoutPrefs.defaults();
  bool _prefsLoaded = false;
  bool _detailViewVisible = false;

  /// 활성 탭의 md 저장 (Ctrl+S·탭 닫기 시 사용).
  Future<void> Function()? saveActiveTab;

  bool get prefsLoaded => _prefsLoaded;

  /// Work · Entity 상세가 메인에 표시 중인지.
  bool get hasOpenDetail =>
      _detailViewVisible && activeTabId != null && activeTab != null;

  bool get hasTabs => tabs.isNotEmpty;

  CollectibleTab? get activeTab {
    if (activeTabId == null) return null;
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }

  WorkCollectibleTab? get activeWorkTab {
    final tab = activeTab;
    return tab is WorkCollectibleTab ? tab : null;
  }

  EntityCollectibleTab? get activeEntityTab {
    final tab = activeTab;
    return tab is EntityCollectibleTab ? tab : null;
  }

  Future<void> loadPrefs() async {
    await layout.load();
    _prefsLoaded = true;
    notifyListeners();
  }

  void openWork(AkashaItem item) {
    final id = WorkCollectibleTab.idFor(item);
    tabs
      ..clear()
      ..add(WorkCollectibleTab(id: id, item: item));
    activeTabId = id;
    _detailViewVisible = true;
    notifyListeners();
  }

  void openEntity(
    UserCatalogEntity entity, {
    EntityJournalEntry? journal,
  }) {
    if (entity.isWorkEntity) return;
    final id = EntityCollectibleTab.idFor(entity.entityId);
    tabs
      ..clear()
      ..add(EntityCollectibleTab(entity: entity, journal: journal));
    activeTabId = id;
    _detailViewVisible = true;
    notifyListeners();
  }

  /// browse(그리드·홈)로 돌아갈 때 상세 세션을 닫습니다.
  void showBrowse() {
    if (!_detailViewVisible && tabs.isEmpty) return;
    _detailViewVisible = false;
    tabs.clear();
    activeTabId = null;
    saveActiveTab = null;
    notifyListeners();
  }

  void selectTab(String id) {
    if (tabs.any((t) => t.id == id)) {
      activeTabId = id;
      _detailViewVisible = true;
      notifyListeners();
    }
  }

  void closeTab(String id) {
    tabs.removeWhere((t) => t.id == id);
    if (activeTabId == id) {
      activeTabId = tabs.isEmpty ? null : tabs.last.id;
      if (tabs.isEmpty) _detailViewVisible = false;
    }
    notifyListeners();
  }

  void markDirty(String id, {bool dirty = true}) {
    for (final tab in tabs) {
      if (tab.id == id) {
        if (tab.isDirty == dirty) return;
        tab.isDirty = dirty;
        notifyListeners();
        return;
      }
    }
  }

  void updateTabItem(String id, AkashaItem item, {bool dirty = false}) {
    for (final tab in tabs) {
      if (tab.id == id && tab is WorkCollectibleTab) {
        tab.item = item;
        tab.isDirty = dirty;
        notifyListeners();
        return;
      }
    }
  }

  void updateEntityTab(
    String id,
    UserCatalogEntity entity,
    EntityJournalEntry? journal, {
    bool dirty = false,
  }) {
    for (final tab in tabs) {
      if (tab.id == id && tab is EntityCollectibleTab) {
        tab.entity = entity;
        tab.journal = journal;
        tab.isDirty = dirty;
        notifyListeners();
        return;
      }
    }
  }

  void preserveEntityDraft(
    String id,
    UserCatalogEntity entity,
    EntityJournalEntry? journal,
  ) {
    for (final tab in tabs) {
      if (tab.id == id && tab is EntityCollectibleTab) {
        tab.entity = entity;
        tab.journal = journal;
        tab.isDirty = true;
        notifyListeners();
        return;
      }
    }
  }

  void syncFromVaultItems(List<AkashaItem> vaultItems) {
    var changed = false;
    for (final tab in tabs) {
      if (tab is! WorkCollectibleTab || tab.isDirty) continue;
      final match = _matchVaultItem(tab.item, vaultItems);
      if (match == null) continue;
      if (_sameItemSnapshot(tab.item, match)) continue;
      tab.item = match;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> syncEntityTabs(String vaultPath) async {
    var changed = false;
    for (final tab in tabs) {
      if (tab is! EntityCollectibleTab || tab.isDirty) continue;
      final path = tab.journal?.storagePath;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        final content = await file.readAsString();
        final updatedJournal = EntityJournalParser.parse(content, path);
        if (updatedJournal != null) {
          if (tab.journal?.body != updatedJournal.body ||
              !listEquals(tab.journal?.tags, updatedJournal.tags)) {
            tab.journal = updatedJournal;
            changed = true;
          }
        }
      } catch (_) {}
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
