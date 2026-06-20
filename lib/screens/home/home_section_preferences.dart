import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';
import '../../models/entity_gallery_sort.dart';
import '../../utils/helpers.dart';

/// 홈 섹션 정렬·접이식 상태 영속화
class HomeSectionPreferences {
  SortCriteria hofSort = SortCriteria.titleAsc;
  SortCriteria librarySort = SortCriteria.titleAsc;
  SortCriteria yearlySort = SortCriteria.titleAsc;
  SortCriteria watchlistSort = SortCriteria.titleAsc;
  EntityGallerySortCriteria entityGallerySort =
      EntityGallerySortCriteria.recentlyAdded;

  bool hofExpanded = true;
  bool libraryExpanded = true;
  bool yearlyExpanded = true;
  bool watchlistExpanded = true;

  /// 글로벌 카탈로그 매체(만화·애니 등) 하위 섹션 접기
  final Set<MediaCategory> collapsedCatalogCategories = {};

  static Future<HomeSectionPreferences> load() async {
    final prefs = HomeSectionPreferences();
    try {
      final sp = await SharedPreferences.getInstance();
      prefs.hofSort = _readSort(sp, 'hof');
      prefs.librarySort = _readSort(sp, 'library');
      prefs.yearlySort = _readSort(sp, 'yearly');
      prefs.watchlistSort = _readSort(sp, 'watchlist');
      prefs.entityGallerySort = _readEntityGallerySort(sp);
      prefs.hofExpanded = sp.getBool('akasha_expanded_hof') ?? true;
      prefs.libraryExpanded = sp.getBool('akasha_expanded_library') ?? true;
      prefs.yearlyExpanded = sp.getBool('akasha_expanded_yearly') ?? true;
      prefs.watchlistExpanded = sp.getBool('akasha_expanded_watchlist') ?? true;
      prefs._loadCollapsedCatalogCategories(sp);
    } catch (e) {
      debugPrint('Error loading section preferences: $e');
    }
    return prefs;
  }

  static EntityGallerySortCriteria _readEntityGallerySort(SharedPreferences sp) {
    final raw = sp.getString('akasha_sort_entity_gallery');
    if (raw == null) return EntityGallerySortCriteria.recentlyAdded;
    return EntityGallerySortCriteria.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => EntityGallerySortCriteria.recentlyAdded,
    );
  }

  Future<void> saveEntityGallerySort(EntityGallerySortCriteria criteria) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('akasha_sort_entity_gallery', criteria.name);
    } catch (e) {
      debugPrint('Error saving entity gallery sort: $e');
    }
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

  bool isCatalogCategoryExpanded(MediaCategory category) =>
      !collapsedCatalogCategories.contains(category);

  void setCatalogCategoryExpanded(
    MediaCategory category,
    bool expanded,
    VoidCallback notify,
  ) {
    if (expanded) {
      collapsedCatalogCategories.remove(category);
    } else {
      collapsedCatalogCategories.add(category);
    }
    _saveCollapsedCatalogCategories();
    notify();
  }

  void _loadCollapsedCatalogCategories(SharedPreferences sp) {
    collapsedCatalogCategories.clear();
    final raw = sp.getString('akasha_collapsed_catalog_categories');
    if (raw == null || raw.isEmpty) return;
    for (final name in raw.split(',')) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      for (final category in MediaCategory.values) {
        if (category.name == trimmed) {
          collapsedCatalogCategories.add(category);
          break;
        }
      }
    }
  }

  Future<void> _saveCollapsedCatalogCategories() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = collapsedCatalogCategories.map((c) => c.name).join(',');
      await sp.setString('akasha_collapsed_catalog_categories', raw);
    } catch (e) {
      debugPrint('Error saving collapsed catalog categories: $e');
    }
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

  void setEntityGallerySort(EntityGallerySortCriteria value, VoidCallback notify) {
    entityGallerySort = value;
    saveEntityGallerySort(value);
    notify();
  }
}
