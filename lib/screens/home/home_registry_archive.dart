import '../../models/akasha_item.dart';
import '../../services/file_service.dart';
import '../../services/works_registry.dart';
import 'home_auto_archive.dart';

/// 검색 등에서 사전 작품 1건을 아카이브에 추가
class HomeRegistryArchive {
  static Future<AkashaItem> persistRegistryWork(
    RegistryWork work, {
    required Future<void> Function() reloadItems,
    required void Function(AkashaItem item) onDemoAdd,
  }) async {
    final item = HomeAutoArchive.itemFromRegistryWork(work);
    final service = AkashaFileService();
    if (service.vaultPath != null) {
      await service.saveItem(item);
      await reloadItems();
    } else {
      onDemoAdd(item);
    }
    return item;
  }
}
