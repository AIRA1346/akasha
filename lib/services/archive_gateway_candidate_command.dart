import '../core/archiving/archive_candidate.dart';
import '../core/archiving/archive_gateway_candidate.dart';
import '../core/archiving/entity_anchor.dart';
import 'archive_gateway_candidate_service.dart';

/// Thin local-command adapter for the first external AKASHA write entry.
///
/// The command deliberately exposes only one non-canonical action:
/// `candidate propose`. It does not edit a Markdown file, promote a candidate,
/// create a Record, or host an AI model. Its structured request is converted
/// into the same Gateway request that app-owned callers use.
class ArchiveGatewayCandidateCommand {
  ArchiveGatewayCandidateCommand({
    ArchiveGatewayCandidateService? gateway,
    DateTime Function()? clock,
  }) : _gateway = gateway ?? ArchiveGatewayCandidateService(),
       _clock = clock ?? DateTime.now;

  final ArchiveGatewayCandidateService _gateway;
  final DateTime Function() _clock;

  Future<ArchiveGatewayCandidateCommandResponse> propose({
    required String vaultPath,
    required Map<String, dynamic> payload,
  }) async {
    ArchiveGatewayCandidateCommandRequest request;
    try {
      request = ArchiveGatewayCandidateCommandRequest.fromJson(payload);
    } on FormatException catch (error) {
      return ArchiveGatewayCandidateCommandResponse.invalid(error.message);
    }

    final now = _clock().toUtc();
    final result = await _gateway.submit(
      vaultPath: vaultPath,
      request: request.toGatewayRequest(now),
      userInitiatedSession: request.toUserInitiatedSession(now),
    );
    return ArchiveGatewayCandidateCommandResponse.fromGateway(result);
  }
}

/// JSON contract accepted from a command-capable external agent.
///
/// The command itself is the explicit local invocation boundary. AKASHA records
/// the supplied actor as a local descriptor, not proof of a provider/model or
/// human identity. A future MCP or desktop integration may supply the same
/// shape through a stronger host-attested session without changing the Vault
/// write path.
class ArchiveGatewayCandidateCommandRequest {
  const ArchiveGatewayCandidateCommandRequest({
    required this.operationId,
    required this.actorBindingId,
    required this.sourceRecordId,
    required this.expectedSourceRevision,
    required this.candidateId,
    required this.entityType,
    required this.title,
    required this.evidence,
    required this.confidence,
    required this.aliases,
    required this.tags,
    this.actorLabel,
    this.source = ArchiveCandidateSource.agent,
    this.proposedEntityId,
    this.duplicateOfEntityId,
  });

  final String operationId;
  final String actorBindingId;
  final String? actorLabel;
  final String sourceRecordId;
  final String expectedSourceRevision;
  final String candidateId;
  final EntityAnchorType entityType;
  final String title;
  final String evidence;
  final double confidence;
  final List<String> aliases;
  final List<String> tags;
  final ArchiveCandidateSource source;
  final String? proposedEntityId;
  final String? duplicateOfEntityId;

  /// Stable across retries of the same command operation so its Gateway intent
  /// fingerprint and candidate/receipt recovery remain stable.
  String get sessionId => 'command_session_$operationId';

  ArchiveGatewayCandidateRequest toGatewayRequest(DateTime now) {
    return ArchiveGatewayCandidateRequest(
      operationId: operationId,
      actorBindingId: actorBindingId,
      authority: ArchiveGatewayAuthorityReference.userInitiatedSession(
        sessionId,
      ),
      expectedSourceRevision: expectedSourceRevision,
      candidate: ArchiveCandidate(
        candidateId: candidateId,
        entityType: entityType,
        title: title,
        sourceRecordId: sourceRecordId,
        evidence: evidence,
        createdAt: now,
        updatedAt: now,
        source: source,
        confidence: confidence,
        aliases: aliases,
        tags: tags,
        proposedEntityId: proposedEntityId,
        duplicateOfEntityId: duplicateOfEntityId,
      ),
    );
  }

  ArchiveGatewayUserInitiatedCandidateSession toUserInitiatedSession(
    DateTime now,
  ) {
    return ArchiveGatewayUserInitiatedCandidateSession(
      sessionId: sessionId,
      actorBindingId: actorBindingId,
      actorLabel: actorLabel,
      allowedSourceRecordIds: {sourceRecordId},
      issuedAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
    );
  }

  factory ArchiveGatewayCandidateCommandRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    _rejectUnknownFields(json, const {
      'operationId',
      'actorBindingId',
      'actorLabel',
      'sourceRecordId',
      'expectedSourceRevision',
      'candidate',
    }, 'request');
    final candidate = _map(json['candidate'], 'candidate');
    _rejectUnknownFields(candidate, const {
      'candidateId',
      'entityType',
      'title',
      'evidence',
      'confidence',
      'aliases',
      'tags',
      'source',
      'proposedEntityId',
      'duplicateOfEntityId',
    }, 'candidate');
    _rejectGatewayOwnedCandidateFields(candidate);
    return ArchiveGatewayCandidateCommandRequest(
      operationId: _requiredString(json['operationId'], 'operationId'),
      actorBindingId: _requiredString(json['actorBindingId'], 'actorBindingId'),
      actorLabel: _optionalString(json['actorLabel']),
      sourceRecordId: _requiredString(json['sourceRecordId'], 'sourceRecordId'),
      expectedSourceRevision: _requiredString(
        json['expectedSourceRevision'],
        'expectedSourceRevision',
      ),
      candidateId: _requiredString(
        candidate['candidateId'],
        'candidate.candidateId',
      ),
      entityType: _enumByName(
        EntityAnchorType.values,
        candidate['entityType'],
        'candidate.entityType',
      ),
      title: _requiredString(candidate['title'], 'candidate.title'),
      evidence: _requiredString(candidate['evidence'], 'candidate.evidence'),
      confidence: _confidence(candidate['confidence']),
      aliases: _stringList(candidate['aliases'], 'candidate.aliases'),
      tags: _stringList(candidate['tags'], 'candidate.tags'),
      source: _source(candidate['source']),
      proposedEntityId: _optionalString(candidate['proposedEntityId']),
      duplicateOfEntityId: _optionalString(candidate['duplicateOfEntityId']),
    );
  }

  static Map<String, dynamic> _map(Object? raw, String field) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    throw FormatException('$field must be an object.');
  }

  static String _requiredString(Object? raw, String field) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) throw FormatException('$field is required.');
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static double _confidence(Object? raw) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '');
    if (value == null) {
      throw const FormatException('candidate.confidence is required.');
    }
    return value;
  }

  static List<String> _stringList(Object? raw, String field) {
    if (raw == null) return const [];
    if (raw is! List) throw FormatException('$field must be an array.');
    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static T _enumByName<T extends Enum>(
    Iterable<T> values,
    Object? raw,
    String field,
  ) {
    final parsed = _optionalEnumByName(values, raw);
    if (parsed == null) throw FormatException('$field is invalid.');
    return parsed;
  }

  static T? _optionalEnumByName<T extends Enum>(
    Iterable<T> values,
    Object? raw,
  ) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static ArchiveCandidateSource _source(Object? raw) {
    if (raw == null || raw.toString().trim().isEmpty) {
      return ArchiveCandidateSource.agent;
    }
    return _enumByName(ArchiveCandidateSource.values, raw, 'candidate.source');
  }

  static void _rejectUnknownFields(
    Map<String, dynamic> value,
    Set<String> allowed,
    String location,
  ) {
    final unknown = value.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw FormatException(
        '$location contains unsupported fields: ${unknown.join(', ')}.',
      );
    }
  }

  static void _rejectGatewayOwnedCandidateFields(Map<String, dynamic> value) {
    const reserved = {
      'status',
      'createdAt',
      'updatedAt',
      'sourceOperationId',
      'actorBindingId',
      'actorLabel',
      'gatewayAuthorizationKind',
      'gatewayAuthorizationId',
      'gatewayGrantId',
      'sourceRecordRevision',
    };
    for (final field in reserved) {
      if (value.containsKey(field)) {
        throw FormatException('candidate.$field is assigned by AKASHA.');
      }
    }
  }
}

/// Stable, machine-readable command result. It intentionally returns only the
/// accepted result identifiers and authority evidence, never a prompt, secret,
/// or full Vault record body.
class ArchiveGatewayCandidateCommandResponse {
  const ArchiveGatewayCandidateCommandResponse._({
    required this.ok,
    required this.applied,
    required this.alreadyApplied,
    this.candidateId,
    this.receiptOperationId,
    this.authorityKind,
    this.authorityId,
    this.errorCode,
    this.message,
  });

  final bool ok;
  final bool applied;
  final bool alreadyApplied;
  final String? candidateId;
  final String? receiptOperationId;
  final String? authorityKind;
  final String? authorityId;
  final String? errorCode;
  final String? message;

  factory ArchiveGatewayCandidateCommandResponse.invalid(String message) {
    return ArchiveGatewayCandidateCommandResponse._(
      ok: false,
      applied: false,
      alreadyApplied: false,
      errorCode: 'command_payload_invalid',
      message: message,
    );
  }

  factory ArchiveGatewayCandidateCommandResponse.fromGateway(
    ArchiveGatewayCandidateResult result,
  ) {
    return ArchiveGatewayCandidateCommandResponse._(
      ok: result.isSuccess,
      applied: result.applied,
      alreadyApplied: result.alreadyApplied,
      candidateId: result.candidate?.candidateId,
      receiptOperationId: result.receipt?.operationId,
      authorityKind: result.receipt?.authority.kind.wireName,
      authorityId: result.receipt?.authority.authorityId,
      errorCode: result.errorCode,
      message: result.message,
    );
  }

  Map<String, Object?> toJson() => {
    'ok': ok,
    'applied': applied,
    'alreadyApplied': alreadyApplied,
    if (candidateId != null) 'candidateId': candidateId,
    if (receiptOperationId != null) 'receiptOperationId': receiptOperationId,
    if (authorityKind != null) 'authorityKind': authorityKind,
    if (authorityId != null) 'authorityId': authorityId,
    if (errorCode != null) 'error': {'code': errorCode, 'message': message},
  };
}
