/// Wave 5 — Record 본문 `[[…]]` wiki link.
enum RecordLinkKind {
  /// `[[entity_id]]` or `[[entity_id|label]]`
  explicitId,

  /// `[[Title]]` — fusion resolve at index/navigate time
  titleOnly,
}

/// Parser output before optional title→entityId resolve.
class ParsedRecordLink {
  const ParsedRecordLink({
    required this.kind,
    required this.raw,
    this.targetEntityId,
    this.targetTitle,
    this.displayLabel,
    this.startOffset = 0,
  });

  final RecordLinkKind kind;
  final String raw;
  final String? targetEntityId;
  final String? targetTitle;
  final String? displayLabel;
  final int startOffset;

  String get unresolvedKey =>
      targetEntityId ?? targetTitle ?? raw;

  String get displayText =>
      displayLabel ?? targetEntityId ?? targetTitle ?? raw;
}

/// Resolved link attached to a vault record path.
class RecordLink {
  const RecordLink({
    required this.sourceRecordId,
    required this.kind,
    required this.raw,
    this.targetEntityId,
    this.targetTitle,
    this.displayLabel,
  });

  final String sourceRecordId;
  final RecordLinkKind kind;
  final String raw;
  final String? targetEntityId;
  final String? targetTitle;
  final String? displayLabel;

  factory RecordLink.fromParsed({
    required String sourceRecordId,
    required ParsedRecordLink parsed,
  }) {
    return RecordLink(
      sourceRecordId: sourceRecordId,
      kind: parsed.kind,
      raw: parsed.raw,
      targetEntityId: parsed.targetEntityId,
      targetTitle: parsed.targetTitle,
      displayLabel: parsed.displayLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'raw': raw,
        if (targetEntityId != null) 'targetEntityId': targetEntityId,
        if (targetTitle != null) 'targetTitle': targetTitle,
        if (displayLabel != null) 'displayLabel': displayLabel,
      };

  static RecordLink fromJson(String sourceRecordId, Map<String, dynamic> json) {
    final kindName = json['kind']?.toString() ?? RecordLinkKind.titleOnly.name;
    final kind = RecordLinkKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => RecordLinkKind.titleOnly,
    );
    return RecordLink(
      sourceRecordId: sourceRecordId,
      kind: kind,
      raw: json['raw']?.toString() ?? '',
      targetEntityId: json['targetEntityId']?.toString(),
      targetTitle: json['targetTitle']?.toString(),
      displayLabel: json['displayLabel']?.toString(),
    );
  }

  String get indexKey => targetEntityId ?? 'title:${targetTitle ?? raw}';
}
