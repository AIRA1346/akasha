import 'dart:io';

import 'package:path/path.dart' as p;

import 'vault_readme_content.dart';
import 'vault_recovery_write_service.dart';

/// 볼트 루트 `VAULT_README.md` — 에이전트·외부 편집기용 자기 설명.
class VaultReadmeWriter {
  static const String readmeFileName = 'VAULT_README.md';

  Future<void> write(String vaultPath) async {
    if (vaultPath.isEmpty) return;

    final file = File(p.join(vaultPath, readmeFileName));
    final content = VaultReadmeContent.build(
      generatedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    await VaultRecoveryWriteService().writeText(
      vaultPath: vaultPath,
      targetPath: file.path,
      content: content,
      reason: 'write_vault_readme',
    );
  }
}
