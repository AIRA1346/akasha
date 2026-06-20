import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/collectible_collection_preset.dart' as collection_builders;
import '../../models/collectible_collection_filter.dart';
import '../../models/collectible_collection.dart';
import '../../models/collectible_collection_id_codec.dart';
import '../../models/collectible_ref.dart';
import '../../models/collectible_kind.dart';
import '../../services/collectible_collection_storage_service.dart';
import 'home_personal_library_controller.dart';

/// Entity 컬렉션 목록·활성 ID·영속화.
class HomeCollectibleCollectionController {
  static const _activeIdKey = 'akasha_active_collectible_collection_id';

  final CollectibleCollectionStorageService _storage;

  List<CollectibleCollection> collections = [];
  String? activeCollectionId;

  HomeCollectibleCollectionController({
    CollectibleCollectionStorageService? storage,
  }) : _storage = storage ?? CollectibleCollectionStorageService();

  CollectibleCollection? get activeCollection {
    if (activeCollectionId == null || collections.isEmpty) return null;
    for (final col in collections) {
      if (col.id == activeCollectionId) return col;
    }
    return null;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      activeCollectionId = prefs.getString(_activeIdKey);
      collections = await _storage.load();
      if (activeCollectionId != null &&
          !collections.any((c) => c.id == activeCollectionId)) {
        activeCollectionId =
            collections.isEmpty ? null : collections.first.id;
      }
    } catch (e) {
      debugPrint('Error loading collectible collections: $e');
      collections = [];
      activeCollectionId = null;
    }
  }

  Future<void> save() async {
    try {
      await _storage.save(collections);
    } catch (e) {
      debugPrint('Error saving collectible collections: $e');
    }
  }

  Future<void> saveActiveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (activeCollectionId != null) {
        await prefs.setString(_activeIdKey, activeCollectionId!);
      } else {
        await prefs.remove(_activeIdKey);
      }
    } catch (e) {
      debugPrint('Error saving active collection id: $e');
    }
  }

  void selectCollection(
    String id, {
    required HomePersonalLibraryController personalLibCtrl,
  }) {
    activeCollectionId = id;
    personalLibCtrl.selectCollectibleCollectionMode();
    saveActiveState();
  }

  void add(
    CollectibleCollection config, {
    required HomePersonalLibraryController personalLibCtrl,
  }) {
    collections.add(config);
    selectCollection(config.id, personalLibCtrl: personalLibCtrl);
  }

  bool remove(String id) {
    collections.removeWhere((c) => c.id == id);
    if (activeCollectionId == id) {
      activeCollectionId =
          collections.isEmpty ? null : collections.first.id;
    }
    return true;
  }

  static CollectibleCollection buildFilterCollection({
    required String title,
    required List<String> tagsAll,
    List<CollectibleKind> kinds = const [CollectibleKind.person],
  }) {
    return CollectibleCollection(
      id: CollectibleCollectionIdCodec.buildUserLocal(),
      title: title,
      mode: CollectibleCollectionMode.filter,
      filter: CollectibleCollectionFilter(
        kinds: kinds,
        tagsAll: tagsAll,
      ),
    );
  }

  static CollectibleCollection buildRelatedWorkCollection({
    required String title,
    required String workId,
    List<CollectibleKind> kinds = const [CollectibleKind.person],
  }) =>
      collection_builders.buildRelatedWorkCollection(
        title: title,
        workId: workId,
        kinds: kinds,
      );

  static CollectibleCollection buildCuratedCollection({
    required String title,
    List<CollectibleRef> memberOrder = const [],
  }) {
    return CollectibleCollection(
      id: CollectibleCollectionIdCodec.buildUserLocal(),
      title: title,
      mode: CollectibleCollectionMode.curated,
      memberOrder: memberOrder,
    );
  }

  Future<void> setMemberOrder(String collectionId, List<CollectibleRef> order) async {
    final col = collections.firstWhere((c) => c.id == collectionId);
    col.memberOrder = CollectibleCollection(
      id: col.id,
      title: col.title,
      mode: col.mode,
      memberOrder: order,
    ).memberOrder;
    col.touch();
    await save();
  }
}
