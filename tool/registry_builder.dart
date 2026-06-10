// ignore_for_file: avoid_print
/// AKASHA Registry Builder (akasha-db v4)
/// Usage: dart run tool/registry_builder.dart [--sync-assets]
///
/// - Validates hash shards under akasha-db/shards/{category}/{00..ff}.json
/// - Regenerates manifest.json (v4) and search_index.json (searchTokens)
/// - Optionally copies akasha-db → assets/registry for app bundle

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';
import 'quality_score_utils.dart';
import 'registry_hash_utils.dart';
import 'registry_v3_utils.dart';
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

const _validDomains = {'subculture', 'generalCulture'};

void main(List<String> args) {
  final syncAssets = args.contains('--sync-assets');
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
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
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
        'sha256': sha256HexUtf8(rawContent),
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

  final searchIndex = allWorks.entries.map((entry) {
    final workId = entry.key;
    final work = entry.value;
    final title = work['title']?.toString() ?? '';
    var titles = parseTitlesJson(work['titles']);
    if (titles.isEmpty && title.isNotEmpty) {
      titles = inferTitlesFromLegacyTitle(title);
    }
    final aliases = (work['aliases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final extensions = work['extensions'] is Map
        ? Map<String, dynamic>.from(work['extensions'] as Map)
        : <String, dynamic>{};
    final searchTokens = buildWorkSearchTokens(
      legacyTitle: title,
      titles: titles,
      aliases: aliases,
      creator: work['creator']?.toString() ?? '',
      tags: (work['tags'] as List?)?.map((e) => e.toString()).toList() ??
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
  }).toList()
    ..sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

  _writeJson('${dbRoot.path}/manifest.json', manifest);
  _writeJson('${dbRoot.path}/search_index.json', searchIndex);

  print('OK: ${allWorks.length} works across ${shardMetas.length} shards');
  print('  → ${dbRoot.path}/manifest.json');
  print('  → ${dbRoot.path}/search_index.json');

  if (syncAssets) {
    final assetsRoot = Directory('${projectRoot.path}/assets/registry');
    _syncAssetsRegistry(
      dbRoot: dbRoot,
      assetsRoot: assetsRoot,
      shardMetas: shardMetas,
    );
    print('  → synced to ${assetsRoot.path}');
  }
}

/// 앱 번들에는 메타 + **전체 샤드** 포함 (GitHub 옛 데이터 덮어쓰기 방지)
void _syncAssetsRegistry({
  required Directory dbRoot,
  required Directory assetsRoot,
  required List<Map<String, dynamic>> shardMetas,
}) {
  if (!assetsRoot.existsSync()) assetsRoot.createSync(recursive: true);

  for (final name in [
    'manifest.json',
    'search_index.json',
    'legacy_aliases.json',
    'id_registry.json',
    'franchise_groups.json',
  ]) {
    final src = File('${dbRoot.path}/$name');
    if (src.existsSync()) {
      src.copySync('${assetsRoot.path}/$name');
    }
  }

  final allPaths = <String>{
    for (final meta in shardMetas) meta['path'] as String,
  };

  var copied = 0;
  for (final relativePath in allPaths) {
    final src = File('${dbRoot.path}/$relativePath');
    if (!src.existsSync()) continue;

    final dest = File('${assetsRoot.path}/$relativePath');
    dest.parent.createSync(recursive: true);
    src.copySync(dest.path);
    copied++;
  }

  _pruneOrphanAssetShards(assetsRoot, allPaths);

  print('  → bundle shards: $copied total (full catalog)');
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
    final members = (value['members'] as List?)?.map((e) => e.toString()) ??
        const <String>[];
    ids.addAll(members.where((id) => id.isNotEmpty));
  });
  return ids;
}

void _pruneOrphanAssetShards(Directory assetsRoot, Set<String> keepPaths) {
  final shardsRoot = Directory('${assetsRoot.path}/shards');
  if (!shardsRoot.existsSync()) return;

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    for (final file in categoryDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final relative =
          'shards/${p.basename(categoryDir.path)}/${p.basename(file.path)}';
      if (!keepPaths.contains(relative)) {
        file.deleteSync();
      }
    }
  }
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
  final domain = work['domain']?.toString() ?? '';
  final title = work['title']?.toString() ?? '';
  final titles = parseTitlesJson(work['titles']);
  final hasTitle = title.isNotEmpty || titles.isNotEmpty;

  if (!_validCategories.contains(category)) {
    errors.add('$shardPath/$workId: invalid category $category');
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

  final poster = work['posterPath']?.toString();
  final posterError = validatePosterUrlForShard(
    poster != null && poster.isNotEmpty ? poster : null,
  );
  if (posterError != null) {
    errors.add('$shardPath/$workId: $posterError');
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

void _copyTree(Directory source, Directory dest, Set<String> names) {
  for (final name in names) {
    final src = FileSystemEntity.typeSync('${source.path}/$name');
    if (src == FileSystemEntityType.notFound) continue;

    final target = '${dest.path}/$name';
    if (src == FileSystemEntityType.directory) {
      _copyDirectory(Directory('${source.path}/$name'), Directory(target));
    } else {
      File('${source.path}/$name').copySync(target);
    }
  }
}

void _copyDirectory(Directory source, Directory destination) {
  if (!destination.existsSync()) destination.createSync(recursive: true);
  for (final entity in source.listSync(recursive: false)) {
    final name = p.basename(entity.path);
    final targetPath = p.join(destination.path, name);
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    }
  }
}

// Minimal path basename helper without package:path in tool
class p {
  static String basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  static String basenameWithoutExtension(String path) {
    final base = basename(path);
    final dot = base.lastIndexOf('.');
    return dot == -1 ? base : base.substring(0, dot);
  }

  static String join(String part1, String part2) {
    if (part1.endsWith('/') || part1.endsWith('\\')) {
      return '$part1$part2';
    }
    return '$part1/$part2';
  }
}
