import '../../core/ports/registry_sync_port.dart';
import '../../services/registry_sync_service.dart';

class RegistrySyncAdapter implements RegistrySyncPort {
  static final RegistrySyncAdapter _instance = RegistrySyncAdapter._internal();
  factory RegistrySyncAdapter() => _instance;
  RegistrySyncAdapter._internal();

  final RegistrySyncService _sync = RegistrySyncService();

  @override
  Future<void> init() => _sync.init();

  @override
  DateTime? get lastSyncTime => _sync.lastSyncTime;

  @override
  Future<bool> shouldAutoSync() => _sync.shouldAutoSync();

  @override
  Future<bool> sync() => _sync.sync();
}
