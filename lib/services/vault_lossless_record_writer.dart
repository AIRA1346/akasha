import 'lossless_frontmatter_patcher.dart';
import 'vault_recovery_write_service.dart';
import 'package:path/path.dart' as p;

/// App-owned fields for each Markdown record family.
///
/// Every field outside the relevant set is user/tool-owned source material and
/// must survive a save unchanged by [VaultLosslessRecordWriter].
abstract final class VaultFrontmatterOwnership {
  static const Set<String> _shared = {
    'schema_version',
    'record_id',
    'record_kind',
    'created_at',
    'updated_at',
    'source',
    'aliases',
    'original_title',
    'external_ids',
    'evidence',
    'links',
    'entity_subtype',
    'source_operation_id',
    'added_at',
  };

  static final Set<String> work = {
    ..._shared,
    ...{
      'work_id',
      'entity_id',
      'entity_type',
      'title',
      'category',
      'domain',
      'poster',
      'rating',
      'work_status',
      'status',
      'my_status',
      'is_hall_of_fame',
      'creator',
      'release_year',
      'tags',
    },
  };

  static final Set<String> entity = {
    ..._shared,
    ...{'entity_id', 'entity_type', 'title', 'tags', 'poster'},
  };

  static final Set<String> journal = {..._shared, 'title'};

  static final Set<String> timeline = {
    ..._shared,
    'title',
    'entity_id',
    'occurred_at',
  };
}

class VaultFrontmatterRejectedException implements Exception {
  const VaultFrontmatterRejectedException({
    required this.message,
    required this.quarantinePath,
  });

  final String message;
  final String quarantinePath;

  @override
  String toString() => '$message Proposed content preserved at $quarantinePath';
}

/// Couples lossless frontmatter patching with recoverable replacement writes.
///
/// Keeping them together makes a rejected YAML patch as non-destructive as a
/// filesystem interruption: the original remains untouched and the proposed
/// content is stored as durable recovery evidence.
class VaultLosslessRecordWriter {
  VaultLosslessRecordWriter({VaultRecoveryWriteService? recoveryWriter})
    : _recoveryWriter = recoveryWriter ?? VaultRecoveryWriteService();

  final VaultRecoveryWriteService _recoveryWriter;

  Future<VaultRecoverableWriteResult> write({
    required String vaultPath,
    required String targetPath,
    required String proposedContent,
    required String reason,
    required Set<String> ownedFrontmatterKeys,
    String? existingContent,
    VaultFileRevision? expectedRevision,
    String? expectedRevisionPath,
  }) async {
    String content = proposedContent;
    final existing = existingContent?.trim();
    if (existing != null && existing.isNotEmpty) {
      try {
        content = LosslessFrontmatterPatcher.patch(
          existingContent: existingContent!,
          proposedContent: proposedContent,
          ownedKeys: ownedFrontmatterKeys,
        );
      } on LosslessFrontmatterPatchException catch (error) {
        final quarantine = await _recoveryWriter.preserveRejectedText(
          vaultPath: vaultPath,
          targetPath: targetPath,
          content: error.proposedContent,
          reason: '${reason}_frontmatter_patch_rejected',
        );
        throw VaultFrontmatterRejectedException(
          message: error.message,
          quarantinePath: quarantine,
        );
      }
    }

    final revisionPath = expectedRevisionPath ?? targetPath;
    final writesSamePath =
        p.normalize(revisionPath) == p.normalize(targetPath);
    if (expectedRevision != null && !writesSamePath) {
      await _recoveryWriter.verifyExpectedRevision(
        vaultPath: vaultPath,
        targetPath: revisionPath,
        expectedRevision: expectedRevision,
        proposedContent: content,
        reason: '${reason}_source_revision_check',
      );
    }

    return _recoveryWriter.writeText(
      vaultPath: vaultPath,
      targetPath: targetPath,
      content: content,
      reason: reason,
      expectedRevision: writesSamePath
          ? expectedRevision
          : const VaultFileRevision.missing(),
    );
  }
}
