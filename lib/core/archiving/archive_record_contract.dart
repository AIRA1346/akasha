import 'package:yaml/yaml.dart';

/// Shared v3 frontmatter contract for durable archive records.
///
/// The vault Markdown file remains the source of truth. This helper only
/// standardizes additive machine-readable fields that app, scripts, and future
/// agents may rely on without knowing each record serializer's private details.
abstract final class ArchiveRecordContract {
  static const int schemaVersion = 3;
  static const String defaultSource = 'app';

  static DateTime? createdAtFromYaml(Map<dynamic, dynamic> yaml) {
    return parseDateTime(
      yaml['created_at'] ??
          yaml['createdAt'] ??
          yaml['added_at'] ??
          yaml['addedAt'],
    );
  }

  static ArchiveRecordMetadata metadataFromYaml(Map<dynamic, dynamic> yaml) {
    return ArchiveRecordMetadata(
      source: _nonEmptyString(yaml['source']) ?? defaultSource,
      aliases: stringList(yaml['aliases']),
      originalTitle:
          _nonEmptyString(yaml['original_title'] ?? yaml['originalTitle']) ??
          '',
      externalIds: stringMap(yaml['external_ids'] ?? yaml['externalIds']),
      evidence: stringList(yaml['evidence']),
      links: structuredLinks(yaml['links']),
      updatedAt: parseDateTime(yaml['updated_at'] ?? yaml['updatedAt']),
      sourceOperationId: _nonEmptyString(
        yaml['source_operation_id'] ?? yaml['sourceOperationId'],
      ),
    );
  }

  static void writeContractFields(
    StringBuffer buffer, {
    required DateTime createdAt,
    ArchiveRecordMetadata metadata = ArchiveRecordMetadata.empty,
  }) {
    final updatedAt = metadata.updatedAt ?? DateTime.now().toUtc();
    buffer
      ..writeln('created_at: "${formatDateTime(createdAt)}"')
      ..writeln('updated_at: "${formatDateTime(updatedAt)}"')
      ..writeln('source: "${escape(metadata.source)}"')
      ..writeln(serializeStringList('aliases', metadata.aliases))
      ..writeln('original_title: "${escape(metadata.originalTitle)}"')
      ..writeln(serializeStringMap('external_ids', metadata.externalIds))
      ..write(serializeStringListBlock('evidence', metadata.evidence))
      ..write(serializeStructuredLinks('links', metadata.links));
    final sourceOperationId = metadata.sourceOperationId?.trim();
    if (sourceOperationId != null && sourceOperationId.isNotEmpty) {
      buffer.writeln('source_operation_id: "${escape(sourceOperationId)}"');
    }
  }

  static DateTime? parseDateTime(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static List<String> stringList(Object? raw) {
    if (raw is YamlList || raw is List) {
      return [
        for (final entry in raw as Iterable)
          if (entry.toString().trim().isNotEmpty) entry.toString().trim(),
      ];
    }
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? const [] : [value];
    }
    return const [];
  }

  static Map<String, String> stringMap(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString().trim() ?? '';
      final value = entry.value?.toString().trim() ?? '';
      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }
    return Map.unmodifiable(result);
  }

  static List<ArchiveStructuredLink> structuredLinks(Object? raw) {
    if (raw is! Iterable) return const [];
    final links = <ArchiveStructuredLink>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final targetId = _nonEmptyString(entry['target_id'] ?? entry['targetId']);
      final targetTitle = _nonEmptyString(
        entry['target_title'] ?? entry['targetTitle'],
      );
      if (targetId == null && targetTitle == null) continue;
      links.add(
        ArchiveStructuredLink(
          targetId: targetId,
          targetTitle: targetTitle,
          relation: _nonEmptyString(entry['relation']) ?? 'related',
          label: _nonEmptyString(entry['label']),
        ),
      );
    }
    return List.unmodifiable(links);
  }

  static String serializeStringList(String key, List<String> values) {
    final clean = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (clean.isEmpty) return '$key: []';
    final escaped = clean.map((value) => '"${escape(value)}"').join(', ');
    return '$key: [$escaped]';
  }

  static String serializeStringListBlock(String key, List<String> values) {
    final clean = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (clean.isEmpty) return '$key: []\n';
    final buffer = StringBuffer()..writeln('$key:');
    for (final value in clean) {
      buffer.writeln('  - "${escape(value)}"');
    }
    return buffer.toString();
  }

  static String serializeStringMap(String key, Map<String, String> values) {
    final clean = Map.fromEntries(
      values.entries.where(
        (entry) => entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
      ),
    );
    if (clean.isEmpty) return '$key: {}';
    final buffer = StringBuffer()..writeln('$key:');
    final keys = clean.keys.toList()..sort();
    for (final idKey in keys) {
      buffer.writeln('  ${escape(idKey)}: "${escape(clean[idKey]!)}"');
    }
    return buffer.toString().trimRight();
  }

  static String serializeStructuredLinks(
    String key,
    List<ArchiveStructuredLink> links,
  ) {
    if (links.isEmpty) return '$key: []\n';
    final buffer = StringBuffer()..writeln('$key:');
    for (final link in links) {
      buffer.writeln('  - relation: "${escape(link.relation)}"');
      if (link.targetId != null && link.targetId!.isNotEmpty) {
        buffer.writeln('    target_id: "${escape(link.targetId!)}"');
      }
      if (link.targetTitle != null && link.targetTitle!.isNotEmpty) {
        buffer.writeln('    target_title: "${escape(link.targetTitle!)}"');
      }
      if (link.label != null && link.label!.isNotEmpty) {
        buffer.writeln('    label: "${escape(link.label!)}"');
      }
    }
    return buffer.toString();
  }

  static String formatDateTime(DateTime value) {
    return value.toIso8601String();
  }

  static String escape(String value) => value.replaceAll('"', '\\"');

  static String? _nonEmptyString(Object? raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class ArchiveRecordMetadata {
  const ArchiveRecordMetadata({
    this.source = ArchiveRecordContract.defaultSource,
    this.aliases = const [],
    this.originalTitle = '',
    this.externalIds = const {},
    this.evidence = const [],
    this.links = const [],
    this.updatedAt,
    this.sourceOperationId,
  });

  static const empty = ArchiveRecordMetadata();

  final String source;
  final List<String> aliases;
  final String originalTitle;
  final Map<String, String> externalIds;
  final List<String> evidence;
  final List<ArchiveStructuredLink> links;
  final DateTime? updatedAt;
  final String? sourceOperationId;

  ArchiveRecordMetadata copyWith({
    String? source,
    List<String>? aliases,
    String? originalTitle,
    Map<String, String>? externalIds,
    List<String>? evidence,
    List<ArchiveStructuredLink>? links,
    DateTime? updatedAt,
    String? sourceOperationId,
  }) {
    return ArchiveRecordMetadata(
      source: source ?? this.source,
      aliases: aliases ?? this.aliases,
      originalTitle: originalTitle ?? this.originalTitle,
      externalIds: externalIds ?? this.externalIds,
      evidence: evidence ?? this.evidence,
      links: links ?? this.links,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceOperationId: sourceOperationId ?? this.sourceOperationId,
    );
  }
}

class ArchiveStructuredLink {
  const ArchiveStructuredLink({
    this.targetId,
    this.targetTitle,
    this.relation = 'related',
    this.label,
  }) : assert(targetId != null || targetTitle != null);

  final String? targetId;
  final String? targetTitle;
  final String relation;
  final String? label;
}
