import '../../core/ports/registry_port.dart';
import '../../core/ports/registry_sync_port.dart';

/// 홈 화면 글로벌 사전 동기화 오케스트레이션
class HomeRegistrySync {
  final RegistryPort registry;
  final RegistrySyncPort sync;
  final bool Function() isMounted;
  final void Function(bool syncing) onSyncingChanged;
  final Future<void> Function() refreshLastSyncTime;
  final Future<void> Function() reloadItems;
  final Future<void> Function({bool showFeedback}) autoArchiveWorks;
  final void Function(String message) showSuccess;
  final void Function(String message) showError;

  HomeRegistrySync({
    required this.registry,
    required this.sync,
    required this.isMounted,
    required this.onSyncingChanged,
    required this.refreshLastSyncTime,
    required this.reloadItems,
    required this.autoArchiveWorks,
    required this.showSuccess,
    required this.showError,
  });

  static String formatLastSyncTime(DateTime? time) {
    if (time == null) return '아직 동기화하지 않음';
    final local = time.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> refreshLastSync() => refreshLastSyncTime();

  Future<void> checkAutoSync() async {
    if (!await sync.shouldAutoSync()) return;

    onSyncingChanged(true);
    final success = await sync.sync();
    if (success) {
      await registry.loadCachedRegistry();
      await reloadItems();
      await autoArchiveWorks();
    }
    if (isMounted()) {
      onSyncingChanged(false);
      await refreshLastSyncTime();
    }
  }

  Future<void> syncNow() async {
    onSyncingChanged(true);

    final success = await sync.sync();
    if (success) {
      await registry.loadCachedRegistry();
      await reloadItems();
      await autoArchiveWorks();
      await refreshLastSyncTime();
      if (isMounted()) {
        showSuccess(
          '작품 사전 동기화 완료! (마지막: ${formatLastSyncTime(sync.lastSyncTime)})',
        );
      }
    } else if (isMounted()) {
      showError('동기화 실패. 네트워크 연결 또는 URL 설정을 확인하세요.');
    }

    if (isMounted()) {
      onSyncingChanged(false);
      await refreshLastSyncTime();
    }
  }
}
