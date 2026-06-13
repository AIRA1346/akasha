import '../../../models/akasha_item.dart';
import '../../../services/file_service.dart';

/// 워크벤치에 열린 작품 탭
class WorkTab {
  final String id;
  AkashaItem item;
  bool isDirty;

  WorkTab({
    required this.id,
    required this.item,
    this.isDirty = false,
  });

  static String idFor(AkashaItem item) {
    if (item.workId.isNotEmpty) return item.workId;
    return AkashaFileService.cacheKeyFor(item);
  }
}
