import 'package:yaml/yaml.dart';

import '../core/archiving/archive_record_contract.dart';
import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../core/utils/unicode_helper.dart';
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

    final rawEntityId = yaml['entity_id']?.toString().trim() ?? '';
    final entityId = UnicodeHelper.toNfc(rawEntityId);
    if (entityId.isEmpty) return null;

    final entityType = _parseEntityType(
      yaml['entity_type']?.toString(),
      entityId,
    );
    final rawTitle = yaml['title']?.toString().trim() ?? entityId;
    final title = UnicodeHelper.toNfc(rawTitle);
    final recordMetadata = ArchiveRecordContract.metadataFromYaml(yaml);
    final addedAt =
        ArchiveRecordContract.createdAtFromYaml(yaml) ?? DateTime.now();
    final aliases = recordMetadata.aliases;
    final tags = EntityTags.parseYaml(yaml['tags']);
    final posterPath = yaml['poster_path']?.toString().trim();
    final sourceOperationId = recordMetadata.sourceOperationId;

    return EntityJournalEntry(
      entityType: entityType,
      entityId: entityId,
      title: title.isNotEmpty ? title : entityId,
      body: split.body.trim(),
      addedAt: addedAt,
      storagePath: filePath,
      aliases: aliases,
      tags: tags,
      posterPath: posterPath,
      sourceOperationId:
          sourceOperationId != null && sourceOperationId.isNotEmpty
          ? sourceOperationId
          : null,
      recordMetadata: recordMetadata,
      entitySubtype: recordMetadata.entitySubtype,
    );
  }

  static String serialize({
    required EntityAnchorType entityType,
    required String entityId,
    required String title,
    required String body,
    DateTime? addedAt,
    List<String> aliases = const [],
    List<String> tags = const [],
    String? posterPath,
    String? sourceOperationId,
    ArchiveRecordMetadata metadata = ArchiveRecordMetadata.empty,
    String entitySubtype = '',
  }) {
    final nfcEntityId = UnicodeHelper.toNfc(entityId);
    final nfcTitle = UnicodeHelper.toNfc(title);
    final added = addedAt ?? DateTime.now();
    final resolvedMetadata = metadata.copyWith(
      aliases: aliases,
      updatedAt: metadata.updatedAt ?? DateTime.now().toUtc(),
      sourceOperationId: sourceOperationId ?? metadata.sourceOperationId,
      entitySubtype: entitySubtype.isNotEmpty ? entitySubtype : metadata.entitySubtype,
    );
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('schema_version: ${ArchiveRecordContract.schemaVersion}')
      ..writeln('record_id: "rec_${_escape(nfcEntityId)}"')
      ..writeln('entity_type: ${entityType.name}')
      ..writeln('entity_id: "${_escape(nfcEntityId)}"')
      ..writeln('record_kind: ${RecordKind.entityJournal.name}')
      ..writeln('title: "${_escape(nfcTitle)}"')
      ..writeln('added_at: "${ArchiveRecordContract.formatDateTime(added)}"');
    ArchiveRecordContract.writeContractFields(
      buffer,
      createdAt: added,
      metadata: resolvedMetadata,
    );
    buffer.writeln(EntityTags.serializeYamlLine(tags));
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

  static String _escape(String value) => ArchiveRecordContract.escape(value);
}

class _Split {
  _Split({required this.frontmatter, required this.body});
  final String frontmatter;
  final String body;
}
