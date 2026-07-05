part of 'record_summary_index_service.dart';

RecordKind _recordKindFromYaml(YamlMap yaml) {
  final raw = _safeYamlString(yaml, 'record_kind');
  if (raw == TimelineEntryParser.legacyRecordKind) {
    return RecordKind.timelineEntry;
  }
  for (final kind in RecordKind.values) {
    if (kind.name == raw) return kind;
  }
  final entityType = _safeYamlString(yaml, 'entity_type');
  if (_safeYamlString(yaml, 'work_id') != null || entityType == 'work') {
    return RecordKind.workJournal;
  }
  if (_safeYamlString(yaml, 'entity_id') != null) {
    return RecordKind.entityJournal;
  }
  return RecordKind.freeformJournal;
}

String _recordIdFromYaml(YamlMap yaml, RecordKind kind, String relativePath) {
  final id = switch (kind) {
    RecordKind.workJournal => _safeYamlString(yaml, 'work_id') ?? _safeYamlString(yaml, 'entity_id'),
    RecordKind.entityJournal => _safeYamlString(yaml, 'entity_id'),
    RecordKind.timelineEntry ||
    RecordKind.freeformJournal => _safeYamlString(yaml, 'record_id'),
  };
  return id?.trim().isNotEmpty == true ? id!.trim() : 'path:$relativePath';
}

String _entityTypeFromYaml(YamlMap yaml, RecordKind kind) {
  final raw = _safeYamlString(yaml, 'entity_type');
  if (raw != null && raw.isNotEmpty) return raw;
  return switch (kind) {
    RecordKind.workJournal => 'work',
    RecordKind.entityJournal => EntityAnchorType.custom.name,
    RecordKind.timelineEntry => 'timeline',
    RecordKind.freeformJournal => 'journal',
  };
}

String? _safeYamlString(YamlMap yaml, String key) {
  YamlNode? node;
  for (final k in yaml.nodes.keys) {
    if (k.toString().trim() == key) {
      node = yaml.nodes[k];
      break;
    }
  }
  if (node == null) return null;

  if (node is YamlScalar) {
    final val = node.value;
    if (val is bool || val is num) {
      final rawText = node.span.text.trim();
      final cleaned = rawText.split('#').first.trim();
      if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
          (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
        return UnicodeHelper.toNfc(cleaned.substring(1, cleaned.length - 1));
      }
      return UnicodeHelper.toNfc(cleaned);
    }
  }

  final val = node.value?.toString().trim();
  return val == null || val.isEmpty ? null : UnicodeHelper.toNfc(val);
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

/// This parser is for AKASHA timestamp fields such as createdAt/updatedAt.
/// It treats timezone-less date-time strings as UTC wall-clock values to avoid host-local timezone drift.
/// It must not be used for date-only semantic fields such as releaseDate, watchedDate, birthDate, or historical dates.
DateTime? _parseVaultInstantAsUtc(Object? raw) {
  if (raw == null) return null;

  // 1. Raw DateTime object preserves its instant and converts to UTC.
  if (raw is DateTime) {
    return raw.toUtc();
  }

  final clean = raw.toString().trim();
  final parsed = DateTime.tryParse(clean);
  if (parsed == null) return null;

  // 2. Fallback to UTC wall-clock cloning when parsed.isUtc is false.
  if (!parsed.isUtc) {
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  // 3. Keep original UTC parsed representation.
  return parsed.toUtc();
}

/// TODO(UA-113): addedAt semantics are not finalized. Do not use this for createdAt/updatedAt or semantic local-date fields.
/// Legacy date parser for backward compatibility of addedAt.
DateTime? _legacyAddedAtDate(Object? raw) {
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
