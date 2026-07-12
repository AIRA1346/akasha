import 'archive_gateway_candidate.dart';

/// Append-only evidence that a Gateway request was accepted and applied.
///
/// Receipts deliberately retain stable identifiers, revisions, authority
/// references, and timing only. They do not contain prompts, API secrets, or
/// a full candidate/record body; semantic provenance remains on the candidate
/// itself and its referenced source record.
class ArchiveGatewayAppliedReceipt {
  const ArchiveGatewayAppliedReceipt({
    required this.operationId,
    required this.intentFingerprint,
    required this.scope,
    required this.actorBindingId,
    required this.authority,
    required this.sourceRecordId,
    required this.sourceRecordRevision,
    required this.candidateId,
    required this.candidateRevision,
    required this.appliedAt,
  });

  static const int schemaVersion = 2;

  final String operationId;
  final String intentFingerprint;
  final ArchiveGatewayScope scope;
  final String actorBindingId;
  final ArchiveGatewayAuthorityReference authority;

  /// Compatibility accessor for old grant-only receipt consumers.
  String? get grantId => authority.grantId;
  final String sourceRecordId;
  final String sourceRecordRevision;
  final String candidateId;
  final String candidateRevision;
  final DateTime appliedAt;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'operationId': operationId,
    'intentFingerprint': intentFingerprint,
    'scope': scope.wireName,
    'actorBindingId': actorBindingId,
    'authorityKind': authority.kind.wireName,
    'authorityId': authority.authorityId,
    if (grantId != null && grantId!.isNotEmpty) 'grantId': grantId,
    'sourceRecordId': sourceRecordId,
    'sourceRecordRevision': sourceRecordRevision,
    'candidateId': candidateId,
    'candidateRevision': candidateRevision,
    'appliedAt': appliedAt.toUtc().toIso8601String(),
  };

  factory ArchiveGatewayAppliedReceipt.fromJson(Map<String, dynamic> json) {
    final legacyGrantId = json['grantId']?.toString() ?? '';
    final authorityKind =
        ArchiveGatewayAuthorityKindWireName.parse(
          json['authorityKind']?.toString(),
        ) ??
        ArchiveGatewayAuthorityKind.durableGrant;
    return ArchiveGatewayAppliedReceipt(
      operationId: json['operationId']?.toString() ?? '',
      intentFingerprint: json['intentFingerprint']?.toString() ?? '',
      scope:
          ArchiveGatewayScopeWireName.parse(json['scope']?.toString()) ??
          ArchiveGatewayScope.candidateCreate,
      actorBindingId: json['actorBindingId']?.toString() ?? '',
      authority: ArchiveGatewayAuthorityReference(
        kind: authorityKind,
        authorityId: json['authorityId']?.toString() ?? legacyGrantId,
      ),
      sourceRecordId: json['sourceRecordId']?.toString() ?? '',
      sourceRecordRevision: json['sourceRecordRevision']?.toString() ?? '',
      candidateId: json['candidateId']?.toString() ?? '',
      candidateRevision: json['candidateRevision']?.toString() ?? '',
      appliedAt:
          DateTime.tryParse(json['appliedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
