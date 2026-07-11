import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../models/registry_work.dart';
import 'home_auto_archive.dart';

/// 검색 등에서 사전 작품 1건을 아카이브에 추가
class HomeRegistryArchive {
  static Future<AkashaItem> persistRegistryWork(
    RegistryWork work, {
    required VaultPort vault,
    required void Function(AkashaItem item) onDemoAdd,
  }) async {
    final item = HomeAutoArchive.itemFromRegistryWork(work);
    if (vault.vaultPath != null) {
      await vault.saveItem(item);
    } else {
      onDemoAdd(item);
    }
    return item;
  }
}
