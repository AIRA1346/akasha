// ignore_for_file: avoid_print
/// AKASHA Registry Builder (akasha-db v3)
/// Usage: dart run tool/registry_builder.dart [--sync-assets]
///
/// - Validates all shard JSON files under akasha-db/shards/
/// - Regenerates manifest.json (v3) and search_index.json (searchTokens)
/// - Optionally copies akasha-db → assets/registry for app bundle

import 'dart:convert';
import 'dart:io';

import 'poster_url_policy.dart';
import 'registry_v3_utils.dart';

final _masterPatternWithYear = RegExp(
  r'^(sub|gen)_(manga|animation|game|book|movie|drama)_(.+)_(\d{4})$',
);
final _masterPatternNoYear = RegExp(
  r'^(sub|gen)_(manga|animation|game|book|movie|drama)_(.+)$',
);

bool _isMasterFormat(String workId) =>
    _masterPatternWithYear.hasMatch(workId) ||
    _masterPatternNoYear.hasMatch(workId);

const _validCategories = {
  'manga',
  'animation',
  'game',
  'book',
  'movie',
  'drama',
};

const _validDomains = {'subculture', 'generalCulture'};

/// 오프라인 bootstrap용 eager 샤드 (나머지는 lazy — 검색 시 온디맨드)
const _eagerBootstrapShardIds = {
  // 서브컬 핵심 IP + 테스트·dogfood 프랜차이즈 샤드
  'manga_C',
  'manga_K',
  'manga_N',
  'manga_O',
  'manga_S',
  'manga_R',
  'manga_numeric',
  'animation_R',
  'book_R',
  'book_8',
  'game_A',
  'game_E',
  'game_L',
  'game_M',
  'book_L',
};

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

  for (final categoryDir in shardsRoot.listSync().whereType<Directory>()) {
    final categoryName = p.basename(categoryDir.path);
    for (final shardFile in categoryDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      final relativePath =
          'shards/$categoryName/${p.basename(shardFile.path)}';
      final shardId = p.basenameWithoutExtension(shardFile.path);
      final content = json.decode(shardFile.readAsStringSync());

      if (content is! Map<String, dynamic>) {
        errors.add('$relativePath: root must be a JSON object');
        continue;
      }

      var entryCount = 0;
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
        allWorks[workId] = work;
        workShardIds[workId] = shardId;
      }

      shardMetas.add({
        'id': shardId,
        'category': categoryName,
        'path': relativePath,
        'eager': _eagerBootstrapShardIds.contains(shardId),
        'entryCount': entryCount,
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
    'version': 3,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'shards': shardMetas,
  };

  final searchIndex = allWorks.entries.map((entry) {
    final workId = entry.key;
    final work = entry.value;
    final poster = work['posterPath'];
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
    if (poster is String &&
        poster.isNotEmpty &&
        poster.startsWith('http')) {
      map['posterPath'] = poster;
    }
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

/// 앱 번들에는 메타 + **eager 샤드만** 포함 (lazy는 GitHub 온디맨드)
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
  ]) {
    final src = File('${dbRoot.path}/$name');
    if (src.existsSync()) {
      src.copySync('${assetsRoot.path}/$name');
    }
  }

  final eagerPaths = <String>{
    for (final meta in shardMetas)
      if (meta['eager'] == true) meta['path'] as String,
  };

  final shardsDest = Directory('${assetsRoot.path}/shards');
  var lazyRemoved = 0;
  if (shardsDest.existsSync()) {
    for (final entity in shardsDest.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      final assetsNorm = assetsRoot.path.replaceAll('\\', '/');
      final relativePath = normalized.startsWith('$assetsNorm/')
          ? normalized.substring(assetsNorm.length + 1)
          : p.basename(normalized);
      if (eagerPaths.contains(relativePath)) continue;
      try {
        entity.deleteSync();
        lazyRemoved++;
      } catch (e) {
        stderr.writeln('  WARN: could not remove lazy bundle shard $relativePath: $e');
      }
    }
  }

  var eagerCopied = 0;
  for (final relativePath in eagerPaths) {
    final src = File('${dbRoot.path}/$relativePath');
    if (!src.existsSync()) continue;

    final dest = File('${assetsRoot.path}/$relativePath');
    dest.parent.createSync(recursive: true);
    src.copySync(dest.path);
    eagerCopied++;
  }

  print(
    '  → bundle shards: $eagerCopied eager, $lazyRemoved lazy removed from assets',
  );
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
  if (!_isMasterFormat(workId)) {
    errors.add('$shardPath: invalid master workId format: $workId');
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
