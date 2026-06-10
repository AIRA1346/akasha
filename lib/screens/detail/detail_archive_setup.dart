import '../../models/akasha_item.dart';
import '../../services/file_service.dart';

/// 아카이브 설정(인라인 생성) 화면이 필요한지 판별합니다.
class DetailArchiveSetup {
  DetailArchiveSetup._();

  static bool needsSetup(AkashaItem item) {
    final service = AkashaFileService();
    if (service.vaultPath == null) {
      return !service.inMemoryCache.containsKey(
        AkashaFileService.cacheKeyFor(item),
      );
    }
    if (!service.isArchivedInVault(item)) return true;
    return _isAutoArchiveStub(item);
  }

  static bool _isAutoArchiveStub(AkashaItem item) {
    if (item.posterPath != null && item.posterPath!.isNotEmpty) return false;
    if (item.rating > 0) return false;
    if (item.memorableQuotes.isNotEmpty) return false;
    if (item.review.isNotEmpty) return false;
    if (item.description.isNotEmpty) return false;
    return true;
  }
}
