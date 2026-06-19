import 'package:yaml/yaml.dart';

import '../core/archiving/journal_entry.dart';

/// `vault/journal/*.md` 파서 — Wave 3.
abstract final class JournalEntryParser {
  static const String journalDirName = 'journal';

  static JournalEntry? parse(String content, String filePath) {
    final split = _splitFrontmatter(content);
    if (split == null) return null;

    final yaml = YamlMap.wrap(loadYaml(split.frontmatter) as YamlMap);
    final kind = yaml['record_kind']?.toString();
    if (kind != 'freeformJournal') return null;

    final recordId = yaml['record_id']?.toString().trim() ?? '';
    if (recordId.isEmpty) return null;

    final title = yaml['title']?.toString().trim() ?? '';
    final addedAt = _parseDateTime(yaml['added_at']) ?? DateTime.now();

    return JournalEntry(
      recordId: recordId,
      title: title.isNotEmpty ? title : recordId,
      body: split.body.trim(),
      addedAt: addedAt,
      storagePath: filePath,
    );
  }

  static String serialize({
    required String recordId,
    required String title,
    required String body,
    DateTime? addedAt,
  }) {
    final added = addedAt ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('record_kind: freeformJournal')
      ..writeln('record_id: "$recordId"')
      ..writeln('title: "${_escape(title)}"')
      ..writeln('added_at: "${added.toIso8601String()}"')
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

  static String _escape(String value) => value.replaceAll('"', '\\"');
}

class _Split {
  _Split({required this.frontmatter, required this.body});
  final String frontmatter;
  final String body;
}
