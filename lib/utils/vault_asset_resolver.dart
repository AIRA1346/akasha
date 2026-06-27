import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/app_vault.dart';

/// Sanctum vault 내 md·이미지 상대경로 해석
class VaultAssetResolver {
  VaultAssetResolver._();

  static File? resolveImageFile(
    String src, {
    String? mdFilePath,
  }) {
    final trimmed = src.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return null;
    }

    final abs = File(trimmed);
    if (p.isAbsolute(trimmed) && abs.existsSync()) return abs;

    final vaultPath = AppVault.port.vaultPath;
    if (vaultPath != null) {
      final fromVault = File(p.join(vaultPath, trimmed.replaceAll('\\', '/')));
      if (fromVault.existsSync()) return fromVault;
    }

    if (mdFilePath != null && mdFilePath.isNotEmpty) {
      final fromMd = File(p.normalize(p.join(p.dirname(mdFilePath), trimmed)));
      if (fromMd.existsSync()) return fromMd;
    }

    return null;
  }
}
