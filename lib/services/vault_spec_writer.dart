import 'dart:io';

import 'package:path/path.dart' as p;

import 'vault_spec_content.dart';

/// Writes the format specification file to the vault under `.akasha/spec/spec_v3.md`.
class VaultSpecWriter {
  static const String specFileName = 'spec_v3.md';

  Future<void> write(String vaultPath) async {
    if (vaultPath.isEmpty) return;

    final specDir = Directory(p.join(vaultPath, '.akasha', 'spec'));
    if (!await specDir.exists()) {
      await specDir.create(recursive: true);
    }

    final file = File(p.join(specDir.path, specFileName));
    await file.writeAsString(VaultSpecContent.content, flush: true);
  }
}
