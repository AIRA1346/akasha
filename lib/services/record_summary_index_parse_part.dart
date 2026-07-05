part of 'record_summary_index_service.dart';

RecordKind _recordKindFromYaml(YamlMap yaml) {
  final raw = _string(yaml['record_kind']);
  if (raw == TimelineEntryParser.legacyRecordKind) {
    return RecordKind.timelineEntry;
  }
  for (final kind in RecordKind.values) {
    if (kind.name == raw) return kind;
  }
  final entityType = _string(yaml['entity_type']);
  if (_string(yaml['work_id']) != null || entityType == 'work') {
    return RecordKind.workJournal;
  }
  if (_string(yaml['entity_id']) != null) {
    return RecordKind.entityJournal;
  }
  return RecordKind.freeformJournal;
}

String _recordIdFromYaml(YamlMap yaml, RecordKind kind, String relativePath) {
  final id = switch (kind) {
    RecordKind.workJournal => _string(yaml['work_id'] ?? yaml['entity_id']),
    RecordKind.entityJournal => _string(yaml['entity_id']),
    RecordKind.timelineEntry ||
    RecordKind.freeformJournal => _string(yaml['record_id']),
  };
  return id?.trim().isNotEmpty == true ? id!.trim() : 'path:$relativePath';
}

String _entityTypeFromYaml(YamlMap yaml, RecordKind kind) {
  final raw = _string(yaml['entity_type']);
  if (raw != null && raw.isNotEmpty) return raw;
  return switch (kind) {
    RecordKind.workJournal => 'work',
    RecordKind.entityJournal => EntityAnchorType.custom.name,
    RecordKind.timelineEntry => 'timeline',
    RecordKind.freeformJournal => 'journal',
  };
}

_Split? _splitFrontmatter(String content) {
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
  return _Split(frontmatter: lines.sublist(1, end).join('\n'));
}

Future<FileStat?> _tryStat(String path) async {
  try {
    return await File(path).stat();
  } catch (_) {
    return null;
  }
}

String? _jsonString(Object? raw) {
  final value = raw?.toString();
  return value == null || value.isEmpty ? null : UnicodeHelper.toNfc(value);
}

String? _string(Object? raw) => _jsonString(raw);

int? _int(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

double? _double(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

DateTime? _date(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toUtc();
}

List<String> _tags(Object? raw) {
  if (raw is YamlList) {
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is String) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

class _Split {
  const _Split({required this.frontmatter});
  final String frontmatter;
}
