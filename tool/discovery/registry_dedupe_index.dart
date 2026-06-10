/// Registry in-memory dedupe index (read-only, externalIds by source).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// `externalIds.{source}` → id set (read-only snapshot).
Set<String> loadRegistryExternalIds(Directory projectRoot, String source) {
  final ids = <String>{};
  if (source.isEmpty) return ids;

  final shardsRoot = Directory(p.join(projectRoot.path, 'akasha-db', 'shards'));
  if (!shardsRoot.existsSync()) return ids;

  for (final file in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! Map) continue;

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final ext = work['externalIds'];
      if (ext is! Map) continue;
      final value = ext[source]?.toString().trim() ?? '';
      if (value.isNotEmpty) ids.add(value);
    }
  }
  return ids;
}

/// @deprecated AniList ingest removed — existing shard ids only.
Set<String> loadRegistryAnilistIds(Directory projectRoot) =>
    loadRegistryExternalIds(projectRoot, 'anilist');
