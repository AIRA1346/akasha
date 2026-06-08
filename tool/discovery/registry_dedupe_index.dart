/// Registry in-memory dedupe index (read-only, anilist externalIds).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// `anilist` source → external id set (read-only snapshot).
Set<String> loadRegistryAnilistIds(Directory projectRoot) {
  final ids = <String>{};
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
      final anilist = ext['anilist']?.toString().trim() ?? '';
      if (anilist.isNotEmpty) ids.add(anilist);
    }
  }
  return ids;
}
