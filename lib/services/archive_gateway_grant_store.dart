import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_gateway_candidate.dart';
import 'vault_recovery_write_service.dart';

/// Local, Vault-owned authority store for the Archive Gateway.
///
/// This is canonical operational state, not an index. It is written through
/// the shared recoverable-write protocol; malformed content is rejected rather
/// than replaced with an empty grant list.
class ArchiveGatewayGrantStore {
  const ArchiveGatewayGrantStore();

  static const int schemaVersion = 1;
  static const String systemDirName = 'system';
  static const String gatewayDirName = 'gateway';
  static const String grantsFileName = 'grants.json';

  Future<List<ArchiveGatewayGrant>> load(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return const [];
    final file = _file(vaultPath);
    if (!await file.exists()) return const [];

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Gateway grants must be a JSON object.');
    }
    final document = Map<String, dynamic>.from(decoded);
    if (_intValue(document['schemaVersion']) != schemaVersion) {
      throw const FormatException('Unsupported Gateway grants schema.');
    }
    final rawGrants = document['grants'];
    if (rawGrants is! List) {
      throw const FormatException('Gateway grants must contain a grants list.');
    }

    final grants = <ArchiveGatewayGrant>[];
    final seen = <String>{};
    for (final raw in rawGrants) {
      if (raw is! Map) {
        throw const FormatException('Gateway grant must be a JSON object.');
      }
      final rawGrant = Map<String, dynamic>.from(raw);
      _validateSerializedGrant(rawGrant);
      final grant = ArchiveGatewayGrant.fromJson(rawGrant);
      _validate(grant);
      if (!seen.add(grant.grantId)) {
        throw FormatException('Duplicate Gateway grant id: ${grant.grantId}');
      }
      grants.add(grant);
    }
    return grants;
  }

  Future<ArchiveGatewayGrant?> lookup(String vaultPath, String grantId) async {
    final id = grantId.trim();
    if (id.isEmpty) return null;
    for (final grant in await load(vaultPath)) {
      if (grant.grantId == id) return grant;
    }
    return null;
  }

  Future<void> upsert({
    required String vaultPath,
    required ArchiveGatewayGrant grant,
  }) async {
    _validate(grant);
    final grants = [...await load(vaultPath)];
    final index = grants.indexWhere((item) => item.grantId == grant.grantId);
    if (index < 0) {
      grants.add(grant);
    } else {
      grants[index] = grant;
    }
    await _write(vaultPath, grants);
  }

  Future<void> revoke({
    required String vaultPath,
    required String grantId,
    DateTime? revokedAt,
  }) async {
    final grants = [...await load(vaultPath)];
    final index = grants.indexWhere((grant) => grant.grantId == grantId.trim());
    if (index < 0) return;
    grants[index] = grants[index].copyWith(
      revokedAt: (revokedAt ?? DateTime.now()).toUtc(),
    );
    await _write(vaultPath, grants);
  }

  Future<void> _write(
    String vaultPath,
    List<ArchiveGatewayGrant> grants,
  ) async {
    final file = _file(vaultPath);
    final current = await VaultFileRevision.fromFile(file);
    final content = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': schemaVersion,
      'grants': grants.map((grant) => grant.toJson()).toList(growable: false),
    });
    await VaultRecoveryWriteService().writeText(
      vaultPath: vaultPath,
      targetPath: file.path,
      content: '$content\n',
      reason: 'archive_gateway_grants',
      expectedRevision: current,
    );
  }

  File _file(String vaultPath) =>
      File(p.join(vaultPath, systemDirName, gatewayDirName, grantsFileName));

  static int? _intValue(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static void _validateSerializedGrant(Map<String, dynamic> raw) {
    for (final field in const ['grantId', 'actorBindingId']) {
      final value = raw[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Gateway grant $field must be a non-empty string.',
        );
      }
    }
    if (raw['scopes'] is! List) {
      throw const FormatException('Gateway grant scopes must be a list.');
    }
    if (_parseUtc(raw['issuedAt']) == null) {
      throw const FormatException(
        'Gateway grant issuedAt must be an ISO timestamp.',
      );
    }
    for (final field in const ['expiresAt', 'revokedAt']) {
      if (raw.containsKey(field) && _parseUtc(raw[field]) == null) {
        throw FormatException('Gateway grant $field must be an ISO timestamp.');
      }
    }
    for (final field in const ['maxCandidateCount', 'maxCandidateBytes']) {
      if (!raw.containsKey(field)) continue;
      final value = _intValue(raw[field]);
      if (value == null || value < 1) {
        throw FormatException(
          'Gateway grant $field must be a positive integer.',
        );
      }
    }
  }

  static DateTime? _parseUtc(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static void _validate(ArchiveGatewayGrant grant) {
    if (!_safeId(grant.grantId)) {
      throw ArgumentError.value(grant.grantId, 'grantId', 'must be a safe id.');
    }
    if (!_safeId(grant.actorBindingId)) {
      throw ArgumentError.value(
        grant.actorBindingId,
        'actorBindingId',
        'must be a safe id.',
      );
    }
    if (grant.scopes.isEmpty) {
      throw ArgumentError.value(grant.scopes, 'scopes', 'must not be empty.');
    }
    if (grant.maxCandidateCount != 1 || grant.maxCandidateBytes < 1) {
      throw ArgumentError(
        'The initial Gateway grant permits exactly one candidate.',
      );
    }
  }

  static bool _safeId(String value) =>
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value.trim()) &&
      !value.contains('..');
}
