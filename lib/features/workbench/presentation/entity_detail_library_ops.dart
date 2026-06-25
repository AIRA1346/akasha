import '../../../models/user_catalog_entity.dart';

/// Entity workspace — 서재 담기 전제 조건.
abstract final class EntityDetailLibraryOps {
  static Future<void> addToLibrary({
    required UserCatalogEntity entity,
    required Future<void> Function(UserCatalogEntity entity)? onAddToLibrary,
    required bool vaultConnected,
    required bool Function() hasJournal,
    required Future<void> Function() saveJournal,
    required void Function(String message) showSnack,
  }) async {
    if (onAddToLibrary == null) return;
    if (!vaultConnected) {
      showSnack('볼트 연결 후 서재에 담을 수 있습니다.');
      return;
    }
    if (!hasJournal()) {
      await saveJournal();
    }
    if (hasJournal()) {
      await onAddToLibrary(entity);
    }
  }
}
