/// Git/CDN 기반 글로벌 사전 동기화 계약.
abstract class RegistrySyncPort {
  Future<void> init();

  DateTime? get lastSyncTime;

  Future<bool> shouldAutoSync();

  Future<bool> sync();
}
