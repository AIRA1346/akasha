import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사이드바 「최근 탐색」용 접근 기록 (workId / entityId).
class RecentExplorationStore {
  RecentExplorationStore({this.onChanged});

  static const _prefsKey = 'akasha_recent_exploration_v1';
  static const maxEntries = 20;

  final VoidCallback? onChanged;

  List<String> _itemKeys = [];
  bool _loaded = false;

  List<String> get itemKeys => List.unmodifiable(_itemKeys);

  static String workKey(String workId) => 'work:$workId';
  static String entityKey(String entityId) => 'entity:$entityId';

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _itemKeys = sp.getStringList(_prefsKey) ?? [];
    } catch (e) {
      debugPrint('RecentExplorationStore.load failed: $e');
      _itemKeys = [];
    }
    _loaded = true;
  }

  Future<void> recordWork(String workId) {
    if (workId.isEmpty) return Future.value();
    return _record(workKey(workId));
  }

  Future<void> recordEntity(String entityId) {
    if (entityId.isEmpty) return Future.value();
    return _record(entityKey(entityId));
  }

  Future<void> _record(String key) async {
    if (!_loaded) await load();

    _itemKeys.remove(key);
    _itemKeys.insert(0, key);
    if (_itemKeys.length > maxEntries) {
      _itemKeys = _itemKeys.take(maxEntries).toList();
    }

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(_prefsKey, _itemKeys);
    } catch (e) {
      debugPrint('RecentExplorationStore.persist failed: $e');
    }
    onChanged?.call();
  }
}
