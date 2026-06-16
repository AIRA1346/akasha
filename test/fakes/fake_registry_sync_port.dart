import 'package:akasha/core/ports/registry_sync_port.dart';

class FakeRegistrySyncPort implements RegistrySyncPort {
  DateTime? lastSyncTimeValue;
  bool shouldAutoSyncResult = false;
  bool syncResult = true;
  int syncCallCount = 0;
  int initCallCount = 0;

  @override
  Future<void> init() async {
    initCallCount++;
  }

  @override
  DateTime? get lastSyncTime => lastSyncTimeValue;

  @override
  Future<bool> shouldAutoSync() async => shouldAutoSyncResult;

  @override
  Future<bool> sync() async {
    syncCallCount++;
    return syncResult;
  }
}
