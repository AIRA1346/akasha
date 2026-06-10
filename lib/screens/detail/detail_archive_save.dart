import '../../models/akasha_item.dart';
import '../../services/file_service.dart';

/// 상세 화면에서 `.md` 아카이브 저장
class DetailArchiveSave {
  DetailArchiveSave._();

  static Future<AkashaItem> save(AkashaItem item) async {
    final service = AkashaFileService();
    if (service.vaultPath != null) {
      await service.saveItem(item);
      return (await _reloadSavedItem(item)) ?? item;
    }
    service.inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
    return item;
  }

  static Future<AkashaItem?> _reloadSavedItem(AkashaItem saved) async {
    final all = await AkashaFileService().loadAllItems();
    for (final loaded in all) {
      if (saved.workId.isNotEmpty && loaded.workId == saved.workId) {
        return loaded;
      }
      if (loaded.title == saved.title && loaded.category == saved.category) {
        return loaded;
      }
    }
    return null;
  }
}
