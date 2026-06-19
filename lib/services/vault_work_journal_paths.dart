import 'package:path/path.dart' as p;

import '../models/akasha_item.dart';
import '../models/enums.dart';

/// Work journal vault path resolution ([vault-layout-v2 §3.1]).
abstract final class VaultWorkJournalPaths {
  static String resolveNewPath({
    required String vaultRoot,
    required AkashaItem item,
    required bool useWorksLayout,
  }) {
    final safeTitle = _makeSafeFilename(item.title);
    if (useWorksLayout) {
      return p.join(vaultRoot, 'works', item.category.name, '$safeTitle.md');
    }
    return p.join(vaultRoot, item.category.name, '$safeTitle.md');
  }

  static String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
