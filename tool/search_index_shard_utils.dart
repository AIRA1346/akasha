// search_index v2 — 카테고리별 shard + manifest (Phase 2.1)
library;

import 'dart:convert';

import 'registry_hash_utils.dart';

const searchIndexManifestVersion = 1;

/// 카테고리별 search_index shard + manifest JSON (akasha-db/search_index/)
Map<String, dynamic> buildSearchIndexManifest({
  required int entryCount,
  required String generatedAt,
  required List<Map<String, dynamic>> shards,
}) {
  return {
    'version': searchIndexManifestVersion,
    'entryCount': entryCount,
    'generatedAt': generatedAt,
    'shards': shards,
  };
}

List<Map<String, dynamic>> groupSearchIndexShards(
  List<Map<String, dynamic>> searchIndex,
) {
  final byCategory = <String, List<Map<String, dynamic>>>{};
  for (final entry in searchIndex) {
    final cat = entry['category']?.toString() ?? 'manga';
    byCategory.putIfAbsent(cat, () => []).add(entry);
  }

  final shards = <Map<String, dynamic>>[];
  for (final cat in byCategory.keys.toList()..sort()) {
    final entries = byCategory[cat]!
      ..sort(
        (a, b) => (a['title'] as String? ?? '')
            .compareTo(b['title'] as String? ?? ''),
      );
    final encoded = const JsonEncoder().convert(entries);
    shards.add({
      'category': cat,
      'path': 'search_index/$cat.json',
      'entryCount': entries.length,
      'sha256': sha256HexUtf8(encoded),
    });
  }
  return shards;
}
