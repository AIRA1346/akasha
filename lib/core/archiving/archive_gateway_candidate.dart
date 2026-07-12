import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'archive_candidate.dart';

/// Narrow authority vocabulary for the Archive write Gateway.
///
/// The first executable slice deliberately exposes only candidate creation.
/// Canonical record edits, relationship assertions, lifecycle transitions,
/// batches, and destructive actions remain outside this boundary.
enum ArchiveGatewayScope { candidateCreate }

extension ArchiveGatewayScopeWireName on ArchiveGatewayScope {
  String get wireName => switch (this) {
    ArchiveGatewayScope.candidateCreate => 'candidate.create',
  };

  static ArchiveGatewayScope? parse(String? raw) {
    for (final value in ArchiveGatewayScope.values) {
      if (value.wireName == raw) return value;
    }
    return null;
  }
}

/// The user-local route that authorized a Gateway request.
///
/// An authorization reference is archival evidence, not a credential. A later
/// transport must prove that it is invoking the trusted local context that
/// issued the reference; callers must never treat an arbitrary string as
/// authority by itself.
enum ArchiveGatewayAuthorityKind { durableGrant, userInitiatedSession }

extension ArchiveGatewayAuthorityKindWireName on ArchiveGatewayAuthorityKind {
  String get wireName => switch (this) {
    ArchiveGatewayAuthorityKind.durableGrant => 'durable_grant',
    ArchiveGatewayAuthorityKind.userInitiatedSession =>
      'user_initiated_session',
  };

  static ArchiveGatewayAuthorityKind? parse(String? raw) {
    for (final value in ArchiveGatewayAuthorityKind.values) {
      if (value.wireName == raw) return value;
    }
    return null;
  }
}

/// Stable reference to the authority route that admitted one Gateway request.
class ArchiveGatewayAuthorityReference {
  const ArchiveGatewayAuthorityReference({
    required this.kind,
    required this.authorityId,
  });

  const ArchiveGatewayAuthorityReference.durableGrant(String grantId)
    : this(
        kind: ArchiveGatewayAuthorityKind.durableGrant,
        authorityId: grantId,
      );

  const ArchiveGatewayAuthorityReference.userInitiatedSession(String sessionId)
    : this(
        kind: ArchiveGatewayAuthorityKind.userInitiatedSession,
        authorityId: sessionId,
      );

  final ArchiveGatewayAuthorityKind kind;
  final String authorityId;

  String? get grantId =>
      kind == ArchiveGatewayAuthorityKind.durableGrant ? authorityId : null;
}

/// Ephemeral authority created when a user starts an AI-assisted archive task.
///
/// It deliberately is not written to the Vault and is not a portable
/// credential. The trusted AKASHA host creates it for the current task, binds
/// it to a local actor and source records, and drops it when the task ends.
/// A future CLI/MCP/socket ingress must prove this context separately; merely
/// sending a session ID over an external transport is never sufficient.
class ArchiveGatewayUserInitiatedCandidateSession {
  const ArchiveGatewayUserInitiatedCandidateSession({
    required this.sessionId,
    required this.actorBindingId,
    required this.allowedSourceRecordIds,
    required this.issuedAt,
    required this.expiresAt,
    this.actorLabel,
    this.maxCandidateBytes = 16384,
  });

  final String sessionId;
  final String actorBindingId;
  final Set<String> allowedSourceRecordIds;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? actorLabel;
  final int maxCandidateBytes;

  bool isActiveAt(DateTime instant) {
    final now = instant.toUtc();
    return !issuedAt.toUtc().isAfter(now) && expiresAt.toUtc().isAfter(now);
  }
}

/// Durable, local authority for a narrowly-scoped Gateway action.
///
/// A grant is stored inside the Vault and is meaningful only for that Vault.
/// It deliberately contains no raw filesystem path, prompt, secret, or model
/// credential. Revocation affects future requests only; it never rewrites a
/// candidate or receipt that was already applied.
class ArchiveGatewayGrant {
  const ArchiveGatewayGrant({
    required this.grantId,
    required this.actorBindingId,
    required this.scopes,
    required this.issuedAt,
    this.actorLabel,
    this.expiresAt,
    this.revokedAt,
    this.maxCandidateCount = 1,
    this.maxCandidateBytes = 16384,
  });

  final String grantId;
  final String actorBindingId;
  final Set<ArchiveGatewayScope> scopes;
  final DateTime issuedAt;
  final String? actorLabel;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final int maxCandidateCount;
  final int maxCandidateBytes;

  bool isActiveAt(DateTime instant) {
    final now = instant.toUtc();
    return revokedAt == null &&
        (expiresAt == null || expiresAt!.toUtc().isAfter(now));
  }

  bool allows(ArchiveGatewayScope scope, DateTime instant) =>
      isActiveAt(instant) && scopes.contains(scope);

  ArchiveGatewayGrant copyWith({DateTime? expiresAt, DateTime? revokedAt}) {
    return ArchiveGatewayGrant(
      grantId: grantId,
      actorBindingId: actorBindingId,
      scopes: scopes,
      issuedAt: issuedAt,
      actorLabel: actorLabel,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
      maxCandidateCount: maxCandidateCount,
      maxCandidateBytes: maxCandidateBytes,
    );
  }

  Map<String, Object?> toJson() => {
    'grantId': grantId,
    'actorBindingId': actorBindingId,
    'scopes': scopes.map((scope) => scope.wireName).toList(growable: false)
      ..sort(),
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    if (actorLabel != null && actorLabel!.trim().isNotEmpty)
      'actorLabel': actorLabel,
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    if (revokedAt != null) 'revokedAt': revokedAt!.toUtc().toIso8601String(),
    'maxCandidateCount': maxCandidateCount,
    'maxCandidateBytes': maxCandidateBytes,
  };

  factory ArchiveGatewayGrant.fromJson(Map<String, dynamic> json) {
    final scopes = <ArchiveGatewayScope>{};
    for (final raw in json['scopes'] as List? ?? const []) {
      final scope = ArchiveGatewayScopeWireName.parse(raw?.toString());
      if (scope != null) scopes.add(scope);
    }
    return ArchiveGatewayGrant(
      grantId: json['grantId']?.toString() ?? '',
      actorBindingId: json['actorBindingId']?.toString() ?? '',
      scopes: scopes,
      issuedAt: _date(json['issuedAt']),
      actorLabel: json['actorLabel']?.toString(),
      expiresAt: _optionalDate(json['expiresAt']),
      revokedAt: _optionalDate(json['revokedAt']),
      maxCandidateCount: _positiveInt(json['maxCandidateCount'], fallback: 1),
      maxCandidateBytes: _positiveInt(
        json['maxCandidateBytes'],
        fallback: 16384,
      ),
    );
  }

  static DateTime _date(Object? raw) =>
      DateTime.tryParse(raw?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _optionalDate(Object? raw) =>
      DateTime.tryParse(raw?.toString() ?? '')?.toUtc();

  static int _positiveInt(Object? raw, {required int fallback}) {
    final value = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    return value ?? fallback;
  }
}

/// A bounded proposal to create exactly one non-canonical archive candidate.
///
/// [expectedSourceRevision] was observed by the caller for the explicit
/// [candidate.sourceRecordId]. The Gateway checks it immediately before it
/// persists the candidate, so a stale tool view cannot silently become a
/// current archival claim.
class ArchiveGatewayCandidateRequest {
  const ArchiveGatewayCandidateRequest({
    required this.operationId,
    required this.actorBindingId,
    required this.authority,
    required this.expectedSourceRevision,
    required this.candidate,
  });

  final String operationId;
  final String actorBindingId;
  final ArchiveGatewayAuthorityReference authority;
  final String expectedSourceRevision;
  final ArchiveCandidate candidate;

  static const ArchiveGatewayScope scope = ArchiveGatewayScope.candidateCreate;

  /// Stable digest for duplicate detection and receipt correlation.
  ///
  /// This is intentionally a digest of semantic request boundaries, not a
  /// storage serialization and not a record of the prompt or model output.
  String get intentFingerprint =>
      ArchiveGatewayIntentFingerprint.forRequest(this);

  int get encodedCandidateBytes =>
      utf8.encode(jsonEncode(candidate.toJson())).length;

  ArchiveCandidate materialize({
    required DateTime appliedAt,
    String? actorLabel,
  }) {
    return candidate.copyWith(
      sourceOperationId: operationId,
      actorBindingId: actorBindingId,
      actorLabel: actorLabel,
      gatewayAuthorizationKind: authority.kind.wireName,
      gatewayAuthorizationId: authority.authorityId,
      gatewayGrantId: authority.grantId,
      sourceRecordRevision: expectedSourceRevision,
      createdAt: appliedAt.toUtc(),
      updatedAt: appliedAt.toUtc(),
    );
  }
}

abstract final class ArchiveGatewayIntentFingerprint {
  static String forRequest(ArchiveGatewayCandidateRequest request) {
    final candidate = request.candidate;
    final payload = <String, Object?>{
      'operation_id': request.operationId.trim(),
      'scope': ArchiveGatewayCandidateRequest.scope.wireName,
      'actor_binding_id': request.actorBindingId.trim(),
      'authorization_kind': request.authority.kind.wireName,
      'authorization_id': request.authority.authorityId.trim(),
      'source_record_revision': request.expectedSourceRevision.trim(),
      'candidate': <String, Object?>{
        'candidate_id': candidate.candidateId.trim(),
        'entity_type': candidate.entityType.name,
        'title': candidate.title.trim(),
        'source_record_id': candidate.sourceRecordId.trim(),
        'evidence': candidate.evidence.trim(),
        'source': candidate.source.name,
        'confidence': candidate.confidence,
        'proposed_entity_id': candidate.proposedEntityId?.trim(),
        'duplicate_of_entity_id': candidate.duplicateOfEntityId?.trim(),
        'aliases': _sortedStrings(candidate.aliases),
        'tags': _sortedStrings(candidate.tags),
      },
    };
    return 'sha256:${crypto.sha256.convert(utf8.encode(jsonEncode(_canonical(payload))))}';
  }

  static String candidateRevision(ArchiveCandidate candidate) =>
      'sha256:${crypto.sha256.convert(utf8.encode(jsonEncode(_canonical(candidate.toJson()))))}';

  /// Compares an interrupted candidate with the request that would have
  /// created it. Gateway authority fields were added after the first
  /// grant-only slice, so an older unreceipted durable-grant candidate may
  /// legitimately lack the generic authority fields. That historical shape is
  /// normalized only for recovery matching; the candidate file is never
  /// rewritten merely to append a receipt.
  static bool candidatesMatchForRecovery({
    required ArchiveCandidate existing,
    required ArchiveCandidate expected,
  }) {
    if (candidateRevision(existing) == candidateRevision(expected)) return true;

    final existingJson = Map<String, Object?>.from(existing.toJson())
      ..remove('schemaVersion');
    final expectedJson = Map<String, Object?>.from(expected.toJson())
      ..remove('schemaVersion');
    final expectedKind = expected.gatewayAuthorizationKind;
    final expectedId = expected.gatewayAuthorizationId;
    if (expectedKind == ArchiveGatewayAuthorityKind.durableGrant.wireName &&
        expectedId != null &&
        expectedId.isNotEmpty &&
        existing.gatewayAuthorizationKind == null &&
        existing.gatewayAuthorizationId == null &&
        existing.gatewayGrantId == expectedId) {
      existingJson['gatewayAuthorizationKind'] = expectedKind;
      existingJson['gatewayAuthorizationId'] = expectedId;
    }
    return jsonEncode(_canonical(existingJson)) ==
        jsonEncode(_canonical(expectedJson));
  }

  static List<String> _sortedStrings(Iterable<String> values) =>
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final entries =
          value.entries
              .map(
                (entry) =>
                    MapEntry(entry.key.toString(), _canonical(entry.value)),
              )
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      return {for (final entry in entries) entry.key: entry.value};
    }
    if (value is Iterable && value is! String) {
      return value.map(_canonical).toList(growable: false);
    }
    return value;
  }
}
