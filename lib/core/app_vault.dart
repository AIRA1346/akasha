import 'ports/vault_port.dart';
import '../data/adapters/markdown_vault_adapter.dart';

/// Application-wide default vault port (ADR-007).
abstract final class AppVault {
  static VaultPort get port => MarkdownVaultAdapter();
}
