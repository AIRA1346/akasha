import '../../../core/app_vault.dart';
import '../../../core/ports/vault_port.dart';

/// Default vault port for workbench surfaces (ADR-007).
abstract final class WorkbenchVault {
  static VaultPort get port => AppVault.port;
}
