import '../../services/registry_sync_service.dart';
import '../../services/works_registry.dart';

/// 홈 화면 글로벌 사전 동기화 오케스트레이션
class HomeRegistrySync {
  final bool Function() isMounted;
  final void Function(bool syncing) onSyncingChanged;
  final Future<void> Function() refreshLastSyncTime;
  final Future<void> Function() reloadItems;
  final Future<void> Function({bool showFeedback}) autoArchiveWorks;
  final void Function(String message) showSuccess;
  final void Function(String message) showError;

  HomeRegistrySync({
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
    final syncService = RegistrySyncService();
    if (!await syncService.shouldAutoSync()) return;

    onSyncingChanged(true);
    final success = await syncService.sync();
    if (success) {
      await WorksRegistry.loadCachedRegistry();
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

    final success = await RegistrySyncService().sync();
    if (success) {
      await WorksRegistry.loadCachedRegistry();
      await reloadItems();
      await autoArchiveWorks();
      await refreshLastSyncTime();
      if (isMounted()) {
        final last = RegistrySyncService().lastSyncTime;
        showSuccess(
          '작품 사전 동기화 완료! (마지막: ${formatLastSyncTime(last)})',
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
