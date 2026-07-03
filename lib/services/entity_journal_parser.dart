import 'package:yaml/yaml.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../models/entity_id_codec.dart';
import '../utils/entity_tags.dart';

/// `vault/entities/{type}/*.md` parser — Wave 4.
abstract final class EntityJournalParser {
  static const String entitiesDirName = 'entities';

  static EntityJournalEntry? parse(String content, String filePath) {
    final split = _splitFrontmatter(content);
    if (split == null) return null;

    final yaml = YamlMap.wrap(loadYaml(split.frontmatter) as YamlMap);
    final kind = yaml['record_kind']?.toString();
    if (kind != RecordKind.entityJournal.name) return null;

    final entityId = yaml['entity_id']?.toString().trim() ?? '';
    if (entityId.isEmpty) return null;

    final entityType = _parseEntityType(
      yaml['entity_type']?.toString(),
      entityId,
    );
    final title = yaml['title']?.toString().trim() ?? entityId;
    final addedAt = _parseDateTime(yaml['added_at']) ?? DateTime.now();
    final tags = EntityTags.parseYaml(yaml['tags']);
    final posterPath = yaml['poster_path']?.toString().trim();

    return EntityJournalEntry(
      entityType: entityType,
      entityId: entityId,
      title: title.isNotEmpty ? title : entityId,
      body: split.body.trim(),
      addedAt: addedAt,
      storagePath: filePath,
      tags: tags,
      posterPath: posterPath,
    );
  }

  static String serialize({
    required EntityAnchorType entityType,
    required String entityId,
    required String title,
    required String body,
    DateTime? addedAt,
    List<String> tags = const [],
    String? posterPath,
  }) {
    final added = addedAt ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('schema_version: 3')
      ..writeln('record_id: "rec_${_escape(entityId)}"')
      ..writeln('entity_type: ${entityType.name}')
      ..writeln('entity_id: "${_escape(entityId)}"')
      ..writeln('record_kind: ${RecordKind.entityJournal.name}')
      ..writeln('title: "${_escape(title)}"')
      ..writeln('added_at: "${added.toIso8601String()}"')
      ..writeln(EntityTags.serializeYamlLine(tags));
    if (posterPath != null && posterPath.isNotEmpty) {
      buffer.writeln('poster_path: "${_escape(posterPath)}"');
    }
    buffer
      ..writeln('---')
      ..writeln()
      ..write(body.trim());
    if (!body.endsWith('\n')) buffer.writeln();
    return buffer.toString();
  }

  static String entitySubdir(EntityAnchorType type) => type.name;

  static EntityAnchorType _parseEntityType(String? raw, String entityId) {
    if (raw != null && raw.isNotEmpty) {
      for (final type in EntityAnchorType.values) {
        if (type.name == raw) return type;
      }
    }
    return EntityIdCodec.typeFromId(entityId) ?? EntityAnchorType.custom;
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
