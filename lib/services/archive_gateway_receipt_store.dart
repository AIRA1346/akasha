import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_gateway_receipt.dart';
import 'vault_recovery_write_service.dart';

/// Append-only idempotency and audit evidence for successful Gateway writes.
///
/// A torn final JSONL line may be ignored while earlier complete receipts stay
/// readable. Failed, stale, denied, or conflicting requests never receive a
/// success receipt and therefore remain retryable after correction.
class ArchiveGatewayReceiptStore {
  const ArchiveGatewayReceiptStore();

  static const String systemDirName = 'system';
  static const String opsDirName = 'ops';
  static const String receiptsFileName = 'gateway_receipts.jsonl';

  Future<ArchiveGatewayAppliedReceipt?> lookup(
    String vaultPath,
    String operationId,
  ) async {
    final id = operationId.trim();
    if (vaultPath.trim().isEmpty || id.isEmpty) return null;
    final file = _file(vaultPath);
    if (!await file.exists()) return null;

    ArchiveGatewayAppliedReceipt? match;
    for (final line in await file.readAsLines()) {
      try {
        final raw = line.trim();
        if (raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final receipt = ArchiveGatewayAppliedReceipt.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (receipt.operationId == id) match = receipt;
      } catch (_) {
        // Never let an interrupted final append hide a prior valid receipt.
      }
    }
    return match;
  }

  Future<ArchiveGatewayAppliedReceipt> appendApplied({
    required String vaultPath,
    required ArchiveGatewayAppliedReceipt receipt,
  }) async {
    final existing = await lookup(vaultPath, receipt.operationId);
    if (existing != null) return existing;

    await VaultRecoveryWriteService().appendJsonLine(
      vaultPath: vaultPath,
      targetPath: _file(vaultPath).path,
      entry: receipt.toJson(),
    );
    return receipt;
  }

  File _file(String vaultPath) =>
      File(p.join(vaultPath, systemDirName, opsDirName, receiptsFileName));
}
