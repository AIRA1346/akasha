import 'dart:math';

import '../../models/entity_id_codec.dart';
import 'entity_anchor.dart';

enum ArchiveCandidateStatus { candidate, promoted, dismissed, merged }

enum ArchiveCandidateSource { user, agent, importTool, registry, script }

/// Lightweight possible entity extracted from records/tools.
///
/// Candidates are intentionally not first-class archive records. Promotion must
/// create an Entity journal and catalog mirror through validated operations.
class ArchiveCandidate {
  const ArchiveCandidate({
    required this.candidateId,
    required this.entityType,
    required this.title,
    required this.sourceRecordId,
    required this.evidence,
    required this.createdAt,
    required this.updatedAt,
    this.status = ArchiveCandidateStatus.candidate,
    this.source = ArchiveCandidateSource.agent,
    this.confidence = 0,
    this.proposedEntityId,
    this.aliases = const [],
    this.tags = const [],
    this.sourceOperationId,
    this.actorBindingId,
    this.actorLabel,
    this.gatewayGrantId,
    this.sourceRecordRevision,
    this.duplicateOfEntityId,
  });

  static const int schemaVersion = 1;

  final String candidateId;
  final EntityAnchorType entityType;
  final String title;
  final String sourceRecordId;
  final String evidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ArchiveCandidateStatus status;
  final ArchiveCandidateSource source;
  final double confidence;
  final String? proposedEntityId;
  final List<String> aliases;
  final List<String> tags;
  final String? sourceOperationId;

  /// Stable local actor binding that created this candidate through the
  /// Archive Gateway. Absent for pre-Gateway candidates and external imports.
  final String? actorBindingId;

  /// Human-readable label for the local actor that proposed this candidate.
  /// It is retained on the candidate so review remains understandable if the
  /// original grant is later revoked or removed.
  final String? actorLabel;

  /// Local authority reference used for a Gateway-created candidate. The
  /// grant's full constraints live in the Vault-owned authority store.
  final String? gatewayGrantId;

  /// Opaque revision of [sourceRecordId] read when this candidate was made.
  /// It makes the candidate's source boundary inspectable without changing the
  /// canonical source record.
  final String? sourceRecordRevision;
  final String? duplicateOfEntityId;

  bool get isOpen => status == ArchiveCandidateStatus.candidate;

  String resolvePromotionEntityId() {
    final proposed = proposedEntityId?.trim();
    if (proposed != null && proposed.isNotEmpty) return proposed;
    return EntityIdCodec.buildUserLocal(entityType);
  }

  ArchiveCandidate copyWith({
    String? candidateId,
    EntityAnchorType? entityType,
    String? title,
    String? sourceRecordId,
    String? evidence,
    DateTime? createdAt,
    DateTime? updatedAt,
    ArchiveCandidateStatus? status,
    ArchiveCandidateSource? source,
    double? confidence,
    String? proposedEntityId,
    List<String>? aliases,
    List<String>? tags,
    String? sourceOperationId,
    String? actorBindingId,
    String? actorLabel,
    String? gatewayGrantId,
    String? sourceRecordRevision,
    String? duplicateOfEntityId,
  }) {
    return ArchiveCandidate(
      candidateId: candidateId ?? this.candidateId,
      entityType: entityType ?? this.entityType,
      title: title ?? this.title,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      evidence: evidence ?? this.evidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      proposedEntityId: proposedEntityId ?? this.proposedEntityId,
      aliases: aliases ?? this.aliases,
      tags: tags ?? this.tags,
      sourceOperationId: sourceOperationId ?? this.sourceOperationId,
      actorBindingId: actorBindingId ?? this.actorBindingId,
      actorLabel: actorLabel ?? this.actorLabel,
      gatewayGrantId: gatewayGrantId ?? this.gatewayGrantId,
      sourceRecordRevision: sourceRecordRevision ?? this.sourceRecordRevision,
      duplicateOfEntityId: duplicateOfEntityId ?? this.duplicateOfEntityId,
    );
  }

  ArchiveCandidate markPromoted({
    required String entityId,
    DateTime? updatedAt,
  }) {
    return copyWith(
      status: ArchiveCandidateStatus.promoted,
      proposedEntityId: entityId,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  ArchiveCandidate markDismissed({DateTime? updatedAt}) {
    return copyWith(
      status: ArchiveCandidateStatus.dismissed,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  ArchiveCandidate markMerged({
    required String duplicateOfEntityId,
    DateTime? updatedAt,
  }) {
    return copyWith(
      status: ArchiveCandidateStatus.merged,
      duplicateOfEntityId: duplicateOfEntityId,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'candidateId': candidateId,
    'entityType': entityType.name,
    'title': title,
    'sourceRecordId': sourceRecordId,
    'evidence': evidence,
    'status': status.name,
    'source': source.name,
    'confidence': confidence,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (proposedEntityId != null && proposedEntityId!.isNotEmpty)
      'proposedEntityId': proposedEntityId,
    if (aliases.isNotEmpty) 'aliases': aliases,
    if (tags.isNotEmpty) 'tags': tags,
    if (sourceOperationId != null && sourceOperationId!.isNotEmpty)
      'sourceOperationId': sourceOperationId,
    if (actorBindingId != null && actorBindingId!.isNotEmpty)
      'actorBindingId': actorBindingId,
    if (actorLabel != null && actorLabel!.isNotEmpty) 'actorLabel': actorLabel,
    if (gatewayGrantId != null && gatewayGrantId!.isNotEmpty)
      'gatewayGrantId': gatewayGrantId,
    if (sourceRecordRevision != null && sourceRecordRevision!.isNotEmpty)
      'sourceRecordRevision': sourceRecordRevision,
    if (duplicateOfEntityId != null && duplicateOfEntityId!.isNotEmpty)
      'duplicateOfEntityId': duplicateOfEntityId,
  };

  factory ArchiveCandidate.fromJson(Map<String, dynamic> json) {
    return ArchiveCandidate(
      candidateId: json['candidateId']?.toString() ?? '',
      entityType: _enumByName(
        EntityAnchorType.values,
        json['entityType']?.toString(),
        EntityAnchorType.object,
      ),
      title: json['title']?.toString() ?? '',
      sourceRecordId: json['sourceRecordId']?.toString() ?? '',
      evidence: json['evidence']?.toString() ?? '',
      status: _enumByName(
        ArchiveCandidateStatus.values,
        json['status']?.toString(),
        ArchiveCandidateStatus.candidate,
      ),
      source: _enumByName(
        ArchiveCandidateSource.values,
        json['source']?.toString(),
        ArchiveCandidateSource.agent,
      ),
      confidence: _double(json['confidence']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      proposedEntityId: json['proposedEntityId']?.toString(),
      aliases: _stringList(json['aliases']),
      tags: _stringList(json['tags']),
      sourceOperationId: json['sourceOperationId']?.toString(),
      actorBindingId: json['actorBindingId']?.toString(),
      actorLabel: json['actorLabel']?.toString(),
      gatewayGrantId: json['gatewayGrantId']?.toString(),
      sourceRecordRevision: json['sourceRecordRevision']?.toString(),
      duplicateOfEntityId: json['duplicateOfEntityId']?.toString(),
    );
  }

  static String buildCandidateId(EntityAnchorType type, {String? suffix}) {
    final token = suffix ?? _randomToken();
    return 'cand_${type.name}_$token';
  }

  static String _randomToken() {
    const alphabet = '0123456789abcdefghijklmnopqrstuv';
    final rand = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[rand.nextInt(alphabet.length)],
    ).join();
  }

  static T _enumByName<T extends Enum>(
    Iterable<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static double _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static DateTime _date(Object? raw) {
    return DateTime.tryParse(raw?.toString() ?? '')?.toUtc() ??
        DateTime.now().toUtc();
  }

  static List<String> _stringList(Object? raw) {
    return (raw as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const [];
  }
}
