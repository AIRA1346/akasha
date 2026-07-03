import 'package:path/path.dart' as p;

import '../core/archiving/entity_anchor.dart';
import '../models/enums.dart';
import 'entity_journal_parser.dart';
import 'vault_safe_filename.dart';

/// Vault Layout v3 canonical path resolver.
///
/// Display titles live in frontmatter; durable record identity lives in the
/// file name when an ID is available.
abstract final class VaultRecordPathResolver {
  static const int canonicalSchemaVersion = 3;

  static String resolveWorkPath({
    required String vaultRoot,
    required String workId,
    required MediaCategory category,
    required String title,
    required bool useWorksLayout,
  }) {
    final idStem = safeIdentityStem(workId);
    if (idStem.isNotEmpty) {
      return p.join(vaultRoot, 'works', category.name, '$idStem.md');
    }

    final titleStem = VaultSafeFilename.fromTitle(title);
    if (useWorksLayout) {
      return p.join(vaultRoot, 'works', category.name, '$titleStem.md');
    }
    return p.join(vaultRoot, category.name, '$titleStem.md');
  }

  static String resolveEntityPath({
    required String vaultRoot,
    required EntityAnchorType entityType,
    required String entityId,
    required String title,
  }) {
    final subdir = EntityJournalParser.entitySubdir(entityType);
    final idStem = safeIdentityStem(entityId);
    final fileStem = idStem.isNotEmpty
        ? idStem
        : VaultSafeFilename.fromTitle(title);
    return p.join(
      vaultRoot,
      EntityJournalParser.entitiesDirName,
      subdir,
      '$fileStem.md',
    );
  }

  static String safeIdentityStem(String id) {
    return id.trim().replaceAll(RegExp(r'[^\w.-]'), '_');
  }
}
