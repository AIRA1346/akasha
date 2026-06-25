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
    // TODO(remove): L2 — docs/draft/LEGACY_REMOVAL_POLICY.md §2.3
    return p.join(vaultRoot, item.category.name, '$safeTitle.md');
  }

  /// 제목 변경 후 저장 경로. 기존 filePath의 parent를 유지하지 않고 레이아웃 설정에 맞는 경로로 이동.
  static String resolvePathAfterTitleChange({
    required String vaultRoot,
    required AkashaItem item,
    required bool useWorksLayout,
  }) =>
      resolveNewPath(
        vaultRoot: vaultRoot,
        item: item,
        useWorksLayout: useWorksLayout,
      );

  /// 삭제 시 시도할 경로 (filePath 우선, 없으면 legacy + works 레이아웃).
  static List<String> resolveDeleteCandidates({
    required String vaultRoot,
    required String title,
    required MediaCategory category,
    String? filePath,
  }) {
    if (filePath != null && filePath.isNotEmpty) {
      return [filePath];
    }
    final safeTitle = _makeSafeFilename(title);
    // TODO(remove): L3 — docs/draft/LEGACY_REMOVAL_POLICY.md §2.3
    return [
      p.join(vaultRoot, category.name, '$safeTitle.md'),
      p.join(vaultRoot, 'works', category.name, '$safeTitle.md'),
    ];
  }

  static String _makeSafeFilename(String title) {
    return title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
