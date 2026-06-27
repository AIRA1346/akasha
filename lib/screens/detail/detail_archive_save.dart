import '../../core/app_vault.dart';
import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../services/file_service.dart';

/// 상세 화면에서 `.md` 아카이브 저장
class DetailArchiveSave {
  DetailArchiveSave._();

  static VaultPort get _vault => AppVault.port;

  static Future<AkashaItem> save(AkashaItem item) async {
    if (_vault.vaultPath != null) {
      await _vault.saveItem(item);
      return (await _reloadSavedItem(item)) ?? item;
    }
    _vault.inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
    return item;
  }

  static Future<AkashaItem?> _reloadSavedItem(AkashaItem saved) async {
    final all = await _vault.loadAllItems();
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
