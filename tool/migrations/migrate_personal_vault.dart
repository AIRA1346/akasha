import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Legacy Categories to migrate
const Set<String> mediaCategories = {
  'manga',
  'animation',
  'game',
  'book',
  'movie',
  'drama',
  'webtoon',
};

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final paths = args.where((a) => !a.startsWith('--')).toList();

  if (paths.isEmpty) {
    print(
      'Usage: dart run tool/migrations/migrate_personal_vault.dart '
      '<vault_path> [--apply]',
    );
    exit(1);
  }

  final vaultPath = paths.first;
  final vaultDir = Directory(vaultPath);
  if (!vaultDir.existsSync()) {
    print('Error: Vault path does not exist: $vaultPath');
    exit(1);
  }

  print('AKASHA Vault Migration Tool (Legacy -> Spec v3)');
  print('Vault Root: $vaultPath');
  print('Mode: ${apply ? "APPLY (Writes changes and deletes old files)" : "DRY-RUN (No changes made)"}');
  print('--------------------------------------------------');

  // Load legacy aliases mapping from project assets
  final projectRoot = _findProjectRoot();
  final aliasFile = File(p.join(projectRoot.path, 'assets', 'registry', 'legacy_aliases.json'));
  final Map<String, String> legacyAliases = {};
  if (aliasFile.existsSync()) {
    try {
      final jsonMap = json.decode(aliasFile.readAsStringSync()) as Map;
      jsonMap.forEach((k, v) => legacyAliases[k.toString()] = v.toString());
      print('Loaded ${legacyAliases.length} legacy aliases mappings.');
    } catch (e) {
      print('Warning: Failed to load legacy_aliases.json: $e');
    }
  } else {
    print('Warning: legacy_aliases.json not found at ${aliasFile.path}.');
  }

  final mdFiles = _collectMdFiles(vaultDir);
  print('Collected ${mdFiles.length} Markdown files in vault.');

  int migratedCount = 0;
  int skippedCount = 0;

  for (final file in mdFiles) {
    final relPath = p.relative(file.path, from: vaultPath).replaceAll('\\', '/');
    final segments = relPath.split('/');
    if (segments.isEmpty) continue;

    final topDir = segments.first;
    final isLegacyWorkDir = mediaCategories.contains(topDir);
    final filename = segments.last;

    // Read file content
    final content = file.readAsStringSync();
    final frontmatter = _extractFrontmatter(content);

    if (frontmatter == null) {
      skippedCount++;
      continue;
    }

    final cleanedFrontmatter = _cleanDuplicateFrontmatterKeys(frontmatter);
    Map<dynamic, dynamic> yaml = {};
    try {
      final loaded = loadYaml(cleanedFrontmatter);
      if (loaded is Map) {
        yaml = loaded;
      }
    } catch (e) {
      print('[Skip] Invalid YAML in $relPath: $e');
      skippedCount++;
      continue;
    }

    final schemaVersion = yaml['schema_version'] ?? yaml['schemaVersion'];
    final workId = yaml['work_id'] ?? yaml['workId'];

    // Determine if it is a work file
    final isWork = isLegacyWorkDir ||
        yaml['record_kind'] == 'workJournal' ||
        (yaml['entity_type'] == 'work') ||
        workId != null;

    if (isWork) {
      // Resolve canonical work ID (wk_xxxx)
      String? resolvedWkId;
      if (workId != null) {
        final idStr = workId.toString().trim();
        if (idStr.startsWith('wk_')) {
          resolvedWkId = idStr;
        } else {
          resolvedWkId = legacyAliases[idStr];
        }
      }

      // If still not resolved, try from filename stem
      if (resolvedWkId == null) {
        final fileStem = p.basenameWithoutExtension(filename);
        if (fileStem.startsWith('wk_')) {
          resolvedWkId = fileStem;
        } else {
          resolvedWkId = legacyAliases[fileStem];
        }
      }

      // Fallback: generate a user-local wk_u_xxxxxxxx ID
      if (resolvedWkId == null) {
        resolvedWkId = _generateUserLocalWkId();
        print('[Info] Generated new user-local ID $resolvedWkId for $relPath');
      }

      // Determine category
      final category = yaml['category']?.toString() ?? topDir;
      if (!mediaCategories.contains(category)) {
        print('[Error] Unknown category "$category" in $relPath. Skipping.');
        skippedCount++;
        continue;
      }

      final canonicalPath = p.join(vaultPath, 'works', category, '$resolvedWkId.md');
      final newRelPath = p.relative(canonicalPath, from: vaultPath).replaceAll('\\', '/');

      // Check if we need to migrate/normalize
      final isAlreadyCanonical = relPath == newRelPath && schemaVersion == 3;

      if (!isAlreadyCanonical) {
        migratedCount++;
        final updatedContent = _normalizeWorkToV3(content, yaml, resolvedWkId, category);

        print('[Migrate] $relPath -> $newRelPath');

        if (apply) {
          // Write new canonical file
          File(canonicalPath).createSync(recursive: true);
          File(canonicalPath).writeAsStringSync(updatedContent);

          // Delete old file if path differs
          if (file.path != canonicalPath) {
            file.deleteSync();
          }
        }
      }
    } else {
      // Non-work files (timeline, journal, entities)
      final recordKind = yaml['record_kind'] ?? yaml['recordKind'];
      final entityType = yaml['entity_type'] ?? yaml['entityType'];

      // Determine record kind if missing
      String? resolvedKind = recordKind?.toString();
      if (resolvedKind == null) {
        if (relPath.startsWith('timeline/')) {
          resolvedKind = 'timelineEntry';
        } else if (relPath.startsWith('journal/')) {
          resolvedKind = 'freeformJournal';
        } else if (relPath.startsWith('entities/')) {
          resolvedKind = 'entityJournal';
        }
      }

      final isV3 = schemaVersion == 3 && resolvedKind != null;

      if (!isV3 && resolvedKind != null) {
        migratedCount++;
        final updatedContent = _normalizeNonWorkToV3(content, yaml, resolvedKind, entityType?.toString());
        print('[Normalize] $relPath (schema_version -> 3)');
        if (apply) {
          file.writeAsStringSync(updatedContent);
        }
      }
    }
  }

  // Cleanup empty legacy directories
  if (apply) {
    for (final cat in mediaCategories) {
      try {
        final dir = Directory(p.join(vaultPath, cat));
        if (dir.existsSync() && dir.listSync().isEmpty) {
          dir.deleteSync();
          print('[Cleanup] Deleted empty legacy directory: $cat');
        }
      } catch (_) {
        // Ignore OS access denied exceptions for locked subdirectories
      }
    }
  }

  print('--------------------------------------------------');
  print('Migration completed.');
  print('Migrated/Normalized: $migratedCount files.');
  print('Skipped/Unchanged: $skippedCount files.');
  if (!apply && migratedCount > 0) {
    print('Note: This was a DRY-RUN. Run with --apply to write changes to disk.');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  return Directory.current;
}

List<File> _collectMdFiles(Directory vaultDir) {
  final files = <File>[];
  _recurseCollect(vaultDir, files);
  return files;
}

void _recurseCollect(Directory dir, List<File> files) {
  try {
    for (final entity in dir.listSync(recursive: false, followLinks: false)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (!name.endsWith('.md')) continue;
        if (name == 'VAULT_README.md' || name == 'NOTES.md') continue;
        files.add(entity);
      } else if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') && name != '.akasha' && name != '.trash') {
          continue;
        }
        _recurseCollect(entity, files);
      }
    }
  } catch (_) {
    // Ignore OS permission denied errors for locked or ghost directories
  }
}

String? _extractFrontmatter(String content) {
  final lines = content.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      return lines.sublist(1, i).join('\n');
    }
  }
  return null;
}

String _generateUserLocalWkId() {
  final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  final stem = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  return 'wk_u_$stem';
}

String _normalizeWorkToV3(String content, Map<dynamic, dynamic> yaml, String wkId, String category) {
  final buffer = StringBuffer();
  buffer.writeln('---');
  buffer.writeln('schema_version: 3');
  buffer.writeln('record_id: "rec_$wkId"');
  buffer.writeln('record_kind: "workJournal"');
  buffer.writeln('entity_type: "work"');
  buffer.writeln('entity_id: "$wkId"');
  buffer.writeln('work_id: "$wkId"');

  // Copy existing essential metadata
  final title = yaml['title']?.toString() ?? '';
  buffer.writeln('title: "${_escape(title)}"');

  final source = yaml['source']?.toString() ?? 'user';
  buffer.writeln('source: "$source"');

  // Timestamps
  final addedAtRaw = yaml['added_at'] ?? yaml['addedAt'] ?? yaml['created_at'] ?? yaml['createdAt'];
  DateTime createdAt = DateTime.now().toUtc();
  if (addedAtRaw != null) {
    createdAt = DateTime.tryParse(addedAtRaw.toString())?.toUtc() ?? createdAt;
  }
  buffer.writeln('created_at: "${createdAt.toIso8601String()}"');

  final updatedAtRaw = yaml['updated_at'] ?? yaml['updatedAt'] ?? addedAtRaw;
  DateTime updatedAt = createdAt;
  if (updatedAtRaw != null) {
    updatedAt = DateTime.tryParse(updatedAtRaw.toString())?.toUtc() ?? updatedAt;
  }
  buffer.writeln('updated_at: "${updatedAt.toIso8601String()}"');

  // Copy other optional fields if present
  if (yaml['original_title'] != null || yaml['originalTitle'] != null) {
    final ot = yaml['original_title'] ?? yaml['originalTitle'];
    buffer.writeln('original_title: "${_escape(ot.toString())}"');
  }
  if (yaml['aliases'] != null) {
    buffer.writeln('aliases: ${json.encode(yaml['aliases'])}');
  }
  if (yaml['external_ids'] != null || yaml['externalIds'] != null) {
    final ext = yaml['external_ids'] ?? yaml['externalIds'];
    buffer.writeln('external_ids: ${json.encode(ext)}');
  }
  if (yaml['evidence'] != null) {
    buffer.writeln('evidence: ${json.encode(yaml['evidence'])}');
  }
  if (yaml['links'] != null) {
    buffer.writeln('links: ${json.encode(yaml['links'])}');
  }
  if (yaml['category'] != null) {
    buffer.writeln('category: $category');
  }
  if (yaml['domain'] != null) {
    buffer.writeln('domain: ${yaml['domain']}');
  }
  if (yaml['poster'] != null) {
    buffer.writeln('poster: "${_escape(yaml['poster'].toString())}"');
  }
  if (yaml['rating'] != null) {
    buffer.writeln('rating: ${yaml['rating']}');
  }
  if (yaml['work_status'] != null || yaml['workStatus'] != null) {
    final ws = yaml['work_status'] ?? yaml['workStatus'];
    buffer.writeln('work_status: "$ws"');
  }
  if (yaml['status'] != null || yaml['my_status'] != null || yaml['myStatus'] != null) {
    final status = yaml['status'] ?? yaml['my_status'] ?? yaml['myStatus'];
    buffer.writeln('status: "$status"');
    buffer.writeln('my_status: "$status"');
  }
  if (yaml['is_hall_of_fame'] != null || yaml['isHallOfFame'] != null) {
    final hof = yaml['is_hall_of_fame'] ?? yaml['isHallOfFame'];
    buffer.writeln('is_hall_of_fame: $hof');
  }
  if (yaml['creator'] != null) {
    buffer.writeln('creator: "${_escape(yaml['creator'].toString())}"');
  }
  if (yaml['release_year'] != null || yaml['releaseYear'] != null) {
    final ry = yaml['release_year'] ?? yaml['releaseYear'];
    buffer.writeln('release_year: $ry');
  }
  if (yaml['tags'] != null) {
    buffer.writeln('tags: ${json.encode(yaml['tags'])}');
  }

  buffer.writeln('---');

  // Extract and append Markdown Body
  final body = _extractBody(content);
  if (body.isNotEmpty) {
    buffer.writeln();
    buffer.write(body);
  }

  return buffer.toString();
}

String _normalizeNonWorkToV3(String content, Map<dynamic, dynamic> yaml, String recordKind, String? entityType) {
  final buffer = StringBuffer();
  buffer.writeln('---');
  buffer.writeln('schema_version: 3');

  // Copy existing YAML map entries except schema_version/record_kind
  yaml.forEach((k, v) {
    final key = k.toString();
    if (key == 'schema_version' ||
        key == 'schemaVersion' ||
        key == 'record_kind' ||
        key == 'recordKind' ||
        key == 'entity_type' ||
        key == 'entityType') {
      return;
    }
    // Convert added_at to created_at and updated_at
    if (key == 'added_at' || key == 'addedAt') {
      final timeStr = v.toString();
      final dt = DateTime.tryParse(timeStr)?.toUtc() ?? DateTime.now().toUtc();
      buffer.writeln('created_at: "${dt.toIso8601String()}"');
      buffer.writeln('updated_at: "${dt.toIso8601String()}"');
      return;
    }
    if (key == 'created_at' || key == 'createdAt') {
      final dt = DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.now().toUtc();
      buffer.writeln('created_at: "${dt.toIso8601String()}"');
      return;
    }
    if (key == 'updated_at' || key == 'updatedAt') {
      final dt = DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.now().toUtc();
      buffer.writeln('updated_at: "${dt.toIso8601String()}"');
      return;
    }

    if (v is String) {
      buffer.writeln('$key: "${_escape(v)}"');
    } else if (v is List || v is Map) {
      buffer.writeln('$key: ${json.encode(v)}');
    } else {
      buffer.writeln('$key: $v');
    }
  });

  buffer.writeln('record_kind: "$recordKind"');
  if (entityType != null) {
    buffer.writeln('entity_type: "$entityType"');
  }
  if (yaml['source'] == null) {
    buffer.writeln('source: "user"');
  }

  // Ensure record_id exists
  if (yaml['record_id'] == null && yaml['recordId'] == null) {
    final id = yaml['entity_id'] ?? yaml['entityId'] ?? yaml['id'] ?? 'rec_${_generateRandomId()}';
    buffer.writeln('record_id: "rec_${_escape(id.toString())}"');
  }

  buffer.writeln('---');

  final body = _extractBody(content);
  if (body.isNotEmpty) {
    buffer.writeln();
    buffer.write(body);
  }

  return buffer.toString();
}

String _extractBody(String content) {
  final lines = content.split('\n');
  int frontMatterCount = 0;
  int bodyStart = 0;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      frontMatterCount++;
      if (frontMatterCount == 2) {
        bodyStart = i + 1;
        break;
      }
    }
  }
  if (bodyStart < lines.length) {
    return lines.sublist(bodyStart).join('\n').trim();
  }
  return '';
}

String _escape(String value) => value.replaceAll('"', '\\"');

String _generateRandomId() {
  final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
}

String _cleanDuplicateFrontmatterKeys(String frontmatter) {
  final lines = frontmatter.split('\n');
  final seenKeys = <String>{};
  final cleanedLines = <String>[];
  for (final line in lines) {
    final trimLine = line.trim();
    if (trimLine.contains(':') && !trimLine.startsWith('#')) {
      final key = trimLine.split(':').first.trim();
      if (seenKeys.contains(key)) {
        continue; // skip duplicate key
      }
      seenKeys.add(key);
    }
    cleanedLines.add(line);
  }
  return cleanedLines.join('\n');
}
