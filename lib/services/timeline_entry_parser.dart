import 'package:yaml/yaml.dart';

import '../core/archiving/archive_record_contract.dart';
import '../core/archiving/timeline_entry.dart';

/// `vault/timeline/*.md` 파서 — Phase 4.1.
abstract final class TimelineEntryParser {
  static const String timelineDirName = 'timeline';

  /// Canonical `record_kind` for new writes (matches [RecordKind.timelineEntry]).
  static const String canonicalRecordKind = 'timelineEntry';

  /// Legacy `record_kind` accepted on read for backward compatibility.
  static const String legacyRecordKind = 'timeline';

  static bool _isTimelineRecordKind(String? raw) {
    final kind = raw?.toString();
    return kind == canonicalRecordKind || kind == legacyRecordKind;
  }

  static TimelineEntry? parse(String content, String filePath) {
    final split = _splitFrontmatter(content);
    if (split == null) return null;

    final yaml = YamlMap.wrap(loadYaml(split.frontmatter) as YamlMap);
    if (!_isTimelineRecordKind(yaml['record_kind']?.toString())) return null;

    final recordId = yaml['record_id']?.toString().trim() ?? '';
    if (recordId.isEmpty) return null;

    final title = yaml['title']?.toString().trim() ?? '';
    final recordMetadata = ArchiveRecordContract.metadataFromYaml(yaml);
    final occurredAt =
        _parseDateTime(yaml['occurred_at']) ??
        ArchiveRecordContract.createdAtFromYaml(yaml) ??
        DateTime.now();
    final addedAt = ArchiveRecordContract.createdAtFromYaml(yaml) ?? occurredAt;
    final entityId = yaml['entity_id']?.toString().trim();

    return TimelineEntry(
      recordId: recordId,
      title: title.isNotEmpty ? title : recordId,
      body: split.body.trim(),
      occurredAt: occurredAt,
      addedAt: addedAt,
      storagePath: filePath,
      entityId: entityId != null && entityId.isNotEmpty ? entityId : null,
      recordMetadata: recordMetadata,
    );
  }

  static String serialize({
    required String recordId,
    required String title,
    required String body,
    required DateTime occurredAt,
    DateTime? addedAt,
    String? entityId,
    ArchiveRecordMetadata metadata = ArchiveRecordMetadata.empty,
  }) {
    final added = addedAt ?? DateTime.now();
    final resolvedMetadata = metadata.copyWith(
      updatedAt: metadata.updatedAt ?? DateTime.now().toUtc(),
    );
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('schema_version: ${ArchiveRecordContract.schemaVersion}')
      ..writeln('record_kind: $canonicalRecordKind')
      ..writeln('record_id: "$recordId"')
      ..writeln('title: "${_escape(title)}"')
      ..writeln(
        'occurred_at: "${ArchiveRecordContract.formatDateTime(occurredAt)}"',
      )
      ..writeln('added_at: "${ArchiveRecordContract.formatDateTime(added)}"');
    ArchiveRecordContract.writeContractFields(
      buffer,
      createdAt: added,
      metadata: resolvedMetadata,
    );
    if (entityId != null && entityId.isNotEmpty) {
      buffer.writeln('entity_id: "$entityId"');
    }
    buffer
      ..writeln('---')
      ..writeln()
      ..write(body.trim());
    if (!body.endsWith('\n')) buffer.writeln();
    return buffer.toString();
  }

  static _Split? _splitFrontmatter(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;
    var end = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        end = i;
        break;
      }
    }
    if (end < 0) return null;
    return _Split(
      frontmatter: lines.sublist(1, end).join('\n'),
      body: lines.sublist(end + 1).join('\n'),
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _escape(String value) => ArchiveRecordContract.escape(value);
}

class _Split {
  _Split({required this.frontmatter, required this.body});
  final String frontmatter;
  final String body;
}
