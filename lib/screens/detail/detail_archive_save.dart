import 'package:path/path.dart' as p;

import '../../core/app_vault.dart';
import '../../core/ports/vault_port.dart';
import '../../models/akasha_item.dart';
import '../../services/file_service.dart';
import '../../services/record_summary_index_service.dart';

/// 상세 화면에서 `.md` 아카이브 저장
class DetailArchiveSave {
  DetailArchiveSave._();

  static VaultPort get _vault => AppVault.port;

  static Future<AkashaItem> save(AkashaItem item) async {
    if (_vault.vaultPath != null) {
      await _vault.saveItem(item);
      return (await _reloadSavedItem(item)) ?? item;
    }
    _vault.inMemoryCache[AkashaFileService.cacheKeyFor(item)] = item;
    return item;
  }

  /// Hydrates the saved Work from one relative path or stable id — never
  /// [VaultPort.loadAllItems].
  static Future<AkashaItem?> _reloadSavedItem(AkashaItem saved) async {
    final vaultPath = _vault.vaultPath;
    if (vaultPath == null || vaultPath.isEmpty) return null;

    final filePath = saved.filePath?.trim();
    if (filePath != null && filePath.isNotEmpty) {
      final root = p.normalize(p.absolute(vaultPath));
      final target = p.normalize(p.absolute(filePath));
      if (p.isWithin(root, target)) {
        final relative = p.relative(target, from: root).replaceAll('\\', '/');
        final loaded = await _vault.loadItemByRelativePath(relative);
        if (loaded != null) return loaded;
      }
    }

    if (saved.workId.isNotEmpty) {
      final summary = await RecordSummaryIndexService().lookupById(
        vaultPath,
        saved.workId,
      );
      if (summary != null && summary.relativePath.isNotEmpty) {
        return _vault.loadItemByRelativePath(summary.relativePath);
      }
    }

    return null;
  }
}
