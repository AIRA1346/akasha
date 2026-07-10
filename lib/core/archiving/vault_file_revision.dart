import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

/// A reproducible identity for one concrete Vault file revision.
///
/// SHA-256 and byte length decide whether content is the same. The modified
/// time is retained as diagnostic evidence and a fast-change hint only; a
/// timestamp-only difference is not a substantive edit or a write conflict.
/// This detects ordinary external changes and accidental corruption. It is not
/// a signature and must not be treated as proof against malicious tampering.
class VaultFileRevision {
  const VaultFileRevision({
    required this.exists,
    this.sha256,
    this.byteLength,
    this.modifiedAtUtc,
  });

  const VaultFileRevision.missing()
    : exists = false,
      sha256 = null,
      byteLength = null,
      modifiedAtUtc = null;

  final bool exists;
  final String? sha256;
  final int? byteLength;
  final DateTime? modifiedAtUtc;

  String get value {
    if (!exists) return 'missing';
    return 'sha256:${sha256 ?? ''};bytes:${byteLength ?? 0};mtime:'
        '${modifiedAtUtc?.toIso8601String() ?? ''}';
  }

  bool sameContentAs(VaultFileRevision other) =>
      exists == other.exists &&
      sha256 == other.sha256 &&
      byteLength == other.byteLength;

  Map<String, Object?> toJson() => {
    'exists': exists,
    if (sha256 != null) 'sha256': sha256,
    if (byteLength != null) 'byte_length': byteLength,
    if (modifiedAtUtc != null)
      'modified_at': modifiedAtUtc!.toUtc().toIso8601String(),
    'value': value,
  };

  static Future<VaultFileRevision> fromFile(File file) async {
    if (!await file.exists()) return const VaultFileRevision.missing();
    final bytes = await file.readAsBytes();
    return fromBytes(
      bytes,
      modifiedAtUtc: (await file.lastModified()).toUtc(),
    );
  }

  static VaultFileRevision fromText(
    String content, {
    DateTime? modifiedAtUtc,
  }) => fromBytes(utf8.encode(content), modifiedAtUtc: modifiedAtUtc);

  static VaultFileRevision fromBytes(
    List<int> bytes, {
    DateTime? modifiedAtUtc,
  }) {
    return VaultFileRevision(
      exists: true,
      sha256: crypto.sha256.convert(bytes).toString(),
      byteLength: bytes.length,
      modifiedAtUtc: modifiedAtUtc?.toUtc(),
    );
  }
}
