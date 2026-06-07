import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/helpers.dart';

/// 홈 섹션 정렬·접이식 상태 영속화
class HomeSectionPreferences {
  SortCriteria hofSort = SortCriteria.titleAsc;
  SortCriteria librarySort = SortCriteria.titleAsc;
  SortCriteria yearlySort = SortCriteria.titleAsc;
  SortCriteria watchlistSort = SortCriteria.titleAsc;

  bool hofExpanded = true;
  bool libraryExpanded = true;
  bool yearlyExpanded = true;
  bool watchlistExpanded = true;

  static Future<HomeSectionPreferences> load() async {
    final prefs = HomeSectionPreferences();
    try {
      final sp = await SharedPreferences.getInstance();
      prefs.hofSort = _readSort(sp, 'hof');
      prefs.librarySort = _readSort(sp, 'library');
      prefs.yearlySort = _readSort(sp, 'yearly');
      prefs.watchlistSort = _readSort(sp, 'watchlist');
      prefs.hofExpanded = sp.getBool('akasha_expanded_hof') ?? true;
      prefs.libraryExpanded = sp.getBool('akasha_expanded_library') ?? true;
      prefs.yearlyExpanded = sp.getBool('akasha_expanded_yearly') ?? true;
      prefs.watchlistExpanded = sp.getBool('akasha_expanded_watchlist') ?? true;
    } catch (e) {
      debugPrint('Error loading section preferences: $e');
    }
    return prefs;
  }

  static SortCriteria _readSort(SharedPreferences sp, String key) {
    final raw = sp.getString('akasha_sort_$key');
    if (raw == null) return SortCriteria.titleAsc;
    return SortCriteria.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SortCriteria.titleAsc,
    );
  }

  Future<void> saveSort(String sectionKey, SortCriteria criteria) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('akasha_sort_$sectionKey', criteria.name);
    } catch (e) {
      debugPrint('Error saving sort for $sectionKey: $e');
    }
  }

  Future<void> saveExpanded(String sectionKey, bool expanded) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('akasha_expanded_$sectionKey', expanded);
    } catch (e) {
      debugPrint('Error saving expanded for $sectionKey: $e');
    }
  }

  void setHofExpanded(bool value, VoidCallback notify) {
    hofExpanded = value;
    saveExpanded('hof', value);
    notify();
  }

  void setLibraryExpanded(bool value, VoidCallback notify) {
    libraryExpanded = value;
    saveExpanded('library', value);
    notify();
  }

  void setYearlyExpanded(bool value, VoidCallback notify) {
    yearlyExpanded = value;
    saveExpanded('yearly', value);
    notify();
  }

  void setWatchlistExpanded(bool value, VoidCallback notify) {
    watchlistExpanded = value;
    saveExpanded('watchlist', value);
    notify();
  }

  void setHofSort(SortCriteria value, VoidCallback notify) {
    hofSort = value;
    saveSort('hof', value);
    notify();
  }

  void setLibrarySort(SortCriteria value, VoidCallback notify) {
    librarySort = value;
    saveSort('library', value);
    notify();
  }

  void setYearlySort(SortCriteria value, VoidCallback notify) {
    yearlySort = value;
    saveSort('yearly', value);
    notify();
  }

  void setWatchlistSort(SortCriteria value, VoidCallback notify) {
    watchlistSort = value;
    saveSort('watchlist', value);
    notify();
  }
}
