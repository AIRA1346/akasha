import '../../../core/ports/vault_port.dart';
import '../../../data/adapters/markdown_vault_adapter.dart';

/// Default vault port for workbench surfaces (ADR-007).
abstract final class WorkbenchVault {
  static VaultPort get port => MarkdownVaultAdapter();
}
