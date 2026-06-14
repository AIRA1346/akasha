import '../../models/akasha_item.dart';
import '../../models/sample_data.dart';
import '../../services/file_service.dart';

/// 볼트·메모리 캐시에서 홈 화면 작품 목록을 구성합니다.
class HomeVaultLoader {
  static Future<List<AkashaItem>> loadItems() async {
    final service = AkashaFileService();
    if (service.vaultPath != null) {
      return await service.loadAllItems();
    }

    final loadedItems = buildSampleData();
    final cache = service.inMemoryCache;
    for (final cachedItem in cache.values) {
      final exists = loadedItems.any(
        (e) =>
            (cachedItem.workId.isNotEmpty && e.workId == cachedItem.workId) ||
            (e.title == cachedItem.title &&
                e.category == cachedItem.category),
      );
      if (!exists) loadedItems.add(cachedItem);
    }
    return loadedItems;
  }
}
