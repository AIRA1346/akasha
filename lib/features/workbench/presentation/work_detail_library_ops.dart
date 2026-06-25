import '../../../models/akasha_item.dart';

/// Work workspace — 서재 담기 전제 조건.
abstract final class WorkDetailLibraryOps {
  static Future<void> addToLibrary({
    required AkashaItem item,
    required Future<void> Function(AkashaItem item)? onAddToLibrary,
    required bool vaultConnected,
    required bool Function() isArchived,
    required Future<void> Function() saveArchive,
    required void Function(String message) showSnack,
  }) async {
    if (onAddToLibrary == null) return;
    if (!vaultConnected) {
      showSnack('볼트 연결 후 서재에 담을 수 있습니다.');
      return;
    }
    if (!isArchived()) {
      await saveArchive();
    }
    await onAddToLibrary(item);
  }
}
