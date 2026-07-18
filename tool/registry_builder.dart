// ignore_for_file: avoid_print
// AKASHA Registry Builder (akasha-db v4)
// Usage: dart run tool/registry_builder.dart
//
// This is an explicit source-data operation. App bundle generation is handled
// separately by registry_bundle_builder.dart and never writes this source.
// - Validates hash shards under akasha-db/shards/{category}/{00..ff}.json
// - Regenerates manifest.json (v4) and search_index.json (searchTokens)

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'quality_score_utils.dart';
import 'registry_hash_utils.dart';
import 'registry_v3_utils.dart';
import 'search_index_shard_utils.dart';
import 'wk_id_utils.dart';

final _masterPatternWithYear = RegExp(
  r'^(sub|gen)_(manga|webtoon|animation|game|book|movie|drama)_(.+)_(\d{4})$',
);
final _masterPatternNoYear = RegExp(
  r'^(sub|gen)_(manga|webtoon|animation|game|book|movie|drama)_(.+)$',
);

bool _isMasterFormat(String workId) =>
    _masterPatternWithYear.hasMatch(workId) ||
    _masterPatternNoYear.hasMatch(workId);

bool _isValidWorkId(String workId) => _isMasterFormat(workId) || isWkId(workId);

const _validCategories = {
  'manga',
  'webtoon',
  'animation',
  'game',
  'book',
  'movie',
  'drama',
};

const _validDomains = {'subculture'};

void main(List<String> args) {
  if (args.any(
    {'--sync-assets', '--bundle-all', '--bundle-eager-only'}.contains,
  )) {
    stderr.writeln(
      'ERROR: source generation and app bundle generation are separate.\n'
      'Run registry_builder.dart without bundle flags, commit/review the source,\n'
      'then run registry_bundle_builder.dart with an explicit source revision.',
    );
    exit(64);
  }
  final projectRoot = _findProjectRoot();
  final dbRoot = Directory('${projectRoot.path}/akasha-db');
  final shardsRoot = Directory('${dbRoot.path}/shards');

  if (!shardsRoot.existsSync()) {
    stderr.writeln('ERROR: ${shardsRoot.path} not found');
    exit(1);
  }

  final errors = <String>[];
  final allWorks = <String, Map<String, dynamic>>{};
  final workShardIds = <String, String>{};
  final shardMetas = <Map<String, dynamic>>[];
  final eagerWorkIds = _loadFranchisePrimaryWorkIds(dbRoot);
  final franchiseMemberIds = _loadFranchiseMemberWorkIds(dbRoot);

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    final categoryName = p.basename(categoryDir.path);
    for (final shardFile in categoryDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    )) {
      final hexKey = p.basenameWithoutExtension(shardFile.path).toLowerCase();
      if (!isV4ShardFileName(hexKey)) {
        errors.add(
          '${shardFile.path}: v4 shard file must be 2-char hex (run migrate_shards_v3_to_v4_hash)',
        );
        continue;
      }

      final relativePath = v4ShardPath(categoryName, hexKey);
      final shardId = v4ShardId(categoryName, hexKey);
      final rawContent = shardFile.readAsStringSync();
      final content = json.decode(rawContent);

      if (content is! Map<String, dynamic>) {
        errors.add('$relativePath: root must be a JSON object');
        continue;
      }

      var entryCount = 0;
      var eager = false;
      for (final entry in content.entries) {
        entryCount++;
        if (entry.value is! Map<String, dynamic>) {
          errors.add('$relativePath: value for ${entry.key} must be object');
          continue;
        }
        final work = Map<String, dynamic>.from(entry.value as Map);
        _validateWork(entry.key, work, relativePath, errors);

        final workId = work['workId']?.toString() ?? entry.key;
        if (allWorks.containsKey(workId)) {
          errors.add('Duplicate workId: $workId');
        }
        final expectedHex = shardHexForWorkId(workId);
        if (expectedHex != hexKey) {
          errors.add(
            '$relativePath: $workId belongs in bucket $expectedHex not $hexKey',
          );
        }
        allWorks[workId] = work;
        workShardIds[workId] = shardId;
        if (eagerWorkIds.contains(workId)) eager = true;
      }

      shardMetas.add({
        'id': shardId,
        'category': categoryName,
        'path': relativePath,
        'eager': eager,
        'entryCount': entryCount,
        'sha256': sha256HexUtf8(_canonicalJsonText(rawContent)),
      });
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Validation failed with ${errors.length} error(s):');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  shardMetas.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  final manifest = {
    'version': 4,
    'shardBits': defaultShardBits,
    'entryCount': allWorks.length,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'shards': shardMetas,
  };

  final searchIndex =
      allWorks.entries.map((entry) {
        final workId = entry.key;
        final work = entry.value;
        final title = work['title']?.toString() ?? '';
        var titles = parseTitlesJson(work['titles']);
        if (titles.isEmpty && title.isNotEmpty) {
          titles = inferTitlesFromLegacyTitle(title);
        }
        final aliases =
            (work['aliases'] as List?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const <String>[];
        final searchTokens = buildWorkSearchTokens(
          legacyTitle: title,
          titles: titles,
          aliases: aliases,
          creator: work['creator']?.toString() ?? '',
          tags:
              (work['tags'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
        );

        final map = <String, dynamic>{
          'workId': workId,
          'title': title,
          'shardId': workShardIds[workId] ?? 'unknown',
          'category': work['category'],
          'domain': work['domain'],
          'creator': work['creator'] ?? '',
          'tags': work['tags'] ?? [],
          'searchTokens': searchTokens,
        };
        if (titles.isNotEmpty) {
          map['titles'] = titles;
        }
        // v1: Tier 1 posterPath — search_index에 복제하지 않음 (유저 볼트만)

        final qualitySignals = resolveQualitySignals(
          work,
          franchiseMember: franchiseMemberIds.contains(workId),
        );
        final qualityScore = computeQualityScore(work, qualitySignals);
        map['qualityScore'] = qualityScore;
        map['qualityTier'] = qualityTierFromScore(qualityScore);

        return map;
      }).toList()..sort(
        (a, b) => (a['title'] as String).compareTo(b['title'] as String),
      );

  final generatedAt = manifest['generatedAt'] as String;

  _writeJson('${dbRoot.path}/manifest.json', manifest);
  _writeJson('${dbRoot.path}/search_index.json', searchIndex);
  _writeShardedSearchIndex(
    dbRoot: dbRoot,
    searchIndex: searchIndex,
    generatedAt: generatedAt,
  );

  print('OK: ${allWorks.length} works across ${shardMetas.length} shards');
  print('  → ${dbRoot.path}/manifest.json');
  print('  → ${dbRoot.path}/search_index.json');
  print('  → ${dbRoot.path}/search_index/ (v2 sharded)');
}

Set<String> _loadFranchisePrimaryWorkIds(Directory dbRoot) {
  final ids = <String>{};
  final file = File('${dbRoot.path}/franchise_groups.json');
  if (!file.existsSync()) return ids;

  final raw = json.decode(file.readAsStringSync());
  if (raw is! Map) return ids;

  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final primary = value['primaryWorkId']?.toString() ?? '';
    if (primary.isNotEmpty) ids.add(primary);
  });
  return ids;
}

Set<String> _loadFranchiseMemberWorkIds(Directory dbRoot) {
  final ids = <String>{};
  final file = File('${dbRoot.path}/franchise_groups.json');
  if (!file.existsSync()) return ids;

  final raw = json.decode(file.readAsStringSync());
  if (raw is! Map) return ids;

  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final members =
        (value['members'] as List?)?.map((e) => e.toString()) ??
        const <String>[];
    ids.addAll(members.where((id) => id.isNotEmpty));
  });
  return ids;
}

bool _isAnilistBulkWork(String workId, Map<String, dynamic> work) {
  final ext = work['extensions'];
  if (ext is Map && ext['seedSource']?.toString() == 'anilist_popularity') {
    return true;
  }
  final parts = workId.split('_');
  if (parts.length >= 4 && RegExp(r'-a\d+$').hasMatch(parts[2])) {
    return true;
  }
  return false;
}

void _validateWork(
  String mapKey,
  Map<String, dynamic> work,
  String shardPath,
  List<String> errors,
) {
  final workId = work['workId']?.toString() ?? mapKey;
  if (mapKey != workId) {
    errors.add('$shardPath: map key $mapKey != workId $workId');
  }
  if (!_isValidWorkId(workId)) {
    errors.add('$shardPath: invalid workId format: $workId');
  }

  final legacyIds = work['legacyIds'];
  if (legacyIds != null && legacyIds is! List) {
    errors.add('$shardPath/$workId: legacyIds must be a JSON array');
  }

  final category = work['category']?.toString() ?? '';
  var domain = work['domain']?.toString() ?? '';
  final title = work['title']?.toString() ?? '';
  final titles = parseTitlesJson(work['titles']);
  final hasTitle = title.isNotEmpty || titles.isNotEmpty;

  if (!_validCategories.contains(category)) {
    errors.add('$shardPath/$workId: invalid category $category');
  }
  if (domain == 'generalCulture') {
    errors.add(
      '$shardPath/$workId: generalCulture deprecated — run tool/migrations/migrate_domain_normalize.dart',
    );
  }
  if (domain.isEmpty) {
    work['domain'] = 'subculture';
    domain = 'subculture';
  }
  if (!_validDomains.contains(domain)) {
    errors.add('$shardPath/$workId: invalid domain $domain');
  }
  if (!hasTitle) {
    errors.add('$shardPath/$workId: title or titles is required');
  }

  if (_isAnilistBulkWork(workId, work)) {
    errors.add(
      '$shardPath/$workId: AniList bulk seed is prohibited (use manual curation)',
    );
  }

  final aliases = work['aliases'];
  if (aliases != null && aliases is! List) {
    errors.add('$shardPath/$workId: aliases must be a JSON array');
  }
  final externalIds = work['externalIds'];
  if (externalIds != null && externalIds is! Map) {
    errors.add('$shardPath/$workId: externalIds must be a JSON object');
  }

  if (work.containsKey('posterPath')) {
    errors.add(
      '$shardPath/$workId: Tier 1 posterPath forbidden — '
      'user Sanctum vault only',
    );
  }
  if (work.containsKey('description')) {
    errors.add(
      '$shardPath/$workId: Tier 1 description forbidden — '
      'user Sanctum vault only',
    );
  }

  final extensions = work['extensions'];
  if (extensions != null && extensions is! Map) {
    errors.add('$shardPath/$workId: extensions must be a JSON object');
  }
}

void _writeJson(String path, Object data) {
  final encoder = const JsonEncoder.withIndent('  ');
  File(path).writeAsStringSync('${encoder.convert(data)}\n');
}

String _canonicalJsonText(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

/// Phase 2.1 — 카테고리별 search_index + manifest (ADR-009)
void _writeShardedSearchIndex({
  required Directory dbRoot,
  required List<Map<String, dynamic>> searchIndex,
  required String generatedAt,
}) {
  final searchDir = Directory('${dbRoot.path}/search_index');
  searchDir.createSync(recursive: true);

  final byCategory = <String, List<Map<String, dynamic>>>{};
  for (final entry in searchIndex) {
    final cat = entry['category']?.toString() ?? 'manga';
    byCategory.putIfAbsent(cat, () => []).add(entry);
  }

  final shardMetas = <Map<String, dynamic>>[];
  for (final cat in byCategory.keys.toList()..sort()) {
    final entries = byCategory[cat]!
      ..sort(
        (a, b) => (a['title'] as String? ?? '').compareTo(
          b['title'] as String? ?? '',
        ),
      );
    final relativePath = 'search_index/$cat.json';
    _writeJson('${dbRoot.path}/$relativePath', entries);
    final encoded = const JsonEncoder().convert(entries);
    shardMetas.add({
      'category': cat,
      'path': relativePath,
      'entryCount': entries.length,
      'sha256': sha256HexUtf8(encoded),
    });
  }

  _writeJson(
    '${searchDir.path}/manifest.json',
    buildSearchIndexManifest(
      entryCount: searchIndex.length,
      generatedAt: generatedAt,
      shards: shardMetas,
    ),
  );

  for (final entity in searchDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final name = p.basenameWithoutExtension(entity.path);
    if (name == 'manifest') continue;
    if (!byCategory.containsKey(name)) {
      try {
        entity.deleteSync();
      } catch (_) {}
    }
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}
