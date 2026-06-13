import 'package:shared_preferences/shared_preferences.dart';

/// 워크벤치 열 너비·잠금·탭 레일 접기
class WorkbenchLayoutPrefs {
  static const _prefix = 'akasha_workbench_';

  double tabRailWidth;
  double infoPanelWidth;
  bool tabRailCollapsed;
  bool tabRailLocked;
  bool infoPanelLocked;

  WorkbenchLayoutPrefs({
    this.tabRailWidth = 160,
    this.infoPanelWidth = 300,
    this.tabRailCollapsed = false,
    this.tabRailLocked = false,
    this.infoPanelLocked = false,
  });

  static WorkbenchLayoutPrefs defaults() => WorkbenchLayoutPrefs();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tabRailWidth = prefs.getDouble('${_prefix}tab_w') ?? 160;
    infoPanelWidth = prefs.getDouble('${_prefix}info_w') ?? 300;
    tabRailCollapsed = prefs.getBool('${_prefix}tab_collapsed') ?? false;
    tabRailLocked = prefs.getBool('${_prefix}tab_locked') ?? false;
    infoPanelLocked = prefs.getBool('${_prefix}info_locked') ?? false;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_prefix}tab_w', tabRailWidth);
    await prefs.setDouble('${_prefix}info_w', infoPanelWidth);
    await prefs.setBool('${_prefix}tab_collapsed', tabRailCollapsed);
    await prefs.setBool('${_prefix}tab_locked', tabRailLocked);
    await prefs.setBool('${_prefix}info_locked', infoPanelLocked);
  }
}
