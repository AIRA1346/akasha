// ignore_for_file: avoid_print
// Catalog scale baseline — Phase 2.0 측정 (수정 전 스냅샷).
//
// Usage: dart run tool/catalog_scale_baseline.dart [--strict]
//
// Phase 2 (search/browse/bundle) 착수 **전**·**후** 비교용.
// 490작에서 수치를 남겨 두면 G1 insert 시 병목 **증명**에 쓴다.
//
// `--strict`: G1+ 번들이 eager-only가 아니거나 assets/registry > 15MB면 exit 1.

import 'dart:convert';
import 'dart:io';

const _eagerOnlyThreshold = 2500;
const _bundleMaxBytes = 15 * 1024 * 1024;

void main(List<String> args) {
  final strict = args.contains('--strict');
  final root = _root();
  final db = Directory('${root.path}/akasha-db');
  final assets = Directory('${root.path}/assets/registry');

  print('AKASHA Catalog Scale Baseline');
  print('root: ${root.path}\n');

  _reportManifest(db, assets);
  _reportSearchIndex(db, assets);
  _reportShards(db, assets);
  final assetsBytes = _reportAssetsTotal(assets);
  final bundleMode = _reportBundleMode(db, assets);

  print('\n--- Phase 2 trigger (architecture-evolution-phases) ---');
  print('search_index parse > 50ms @490 → watch');
  print('entryCount > 1000 OR master_index 체감 지연 → Phase 2.1~2.2');
  print('entryCount > 2500 OR assets/registry > 5MB → Phase 2.3 eager-only (ADR-010)');
  print('APK assets/registry > 15MB → CI/release mandatory eager-only');

  if (!strict) return;

  final entryCount = _readEntryCount(db);
  final errors = <String>[];

  if (entryCount > _eagerOnlyThreshold && bundleMode != 'eager-only') {
    errors.add(
      'bundle mode is "$bundleMode" (expected eager-only at entryCount $entryCount)',
    );
  }
  if (assetsBytes > _bundleMaxBytes) {
    errors.add(
      'assets/registry is ${_mb(assetsBytes)} MB (limit ${_mb(_bundleMaxBytes)} MB)',
    );
  }

  if (errors.isEmpty) {
    print('\nOK: catalog_scale_baseline --strict');
    return;
  }

  stderr.writeln('\nFAIL: catalog_scale_baseline --strict');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exit(1);
}

void _reportManifest(Directory db, Directory assets) {
  for (final label in ['akasha-db', 'assets/registry']) {
    final dir = label == 'akasha-db' ? db : assets;
    final file = File('${dir.path}/manifest.json');
    if (!file.existsSync()) {
      print('[manifest] $label: missing');
      continue;
    }
    final raw = file.readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final entryCount = json['entryCount'];
    final shardBits = json['shardBits'];
    final shards = json['shards'];
    final shardList = shards is List ? shards.length : '?';
    print('[manifest] $label');
    print('  entryCount: $entryCount');
    print('  shardBits: $shardBits');
    print('  shard entries: $shardList');
    print('  file size: ${_kb(raw.length)} KB');
  }
}

void _reportSearchIndex(Directory db, Directory assets) {
  for (final label in ['akasha-db', 'assets/registry']) {
    final dir = label == 'akasha-db' ? db : assets;
    _reportMonolithicSearchIndex(dir, label);
    _reportShardedSearchIndex(dir, label);
  }
}

void _reportMonolithicSearchIndex(Directory dir, String label) {
  final file = File('${dir.path}/search_index.json');
  if (!file.existsSync()) {
    print('[search_index] $label (monolithic): missing');
    return;
  }
  final bytes = file.lengthSync();
  final raw = file.readAsStringSync();
  final sw = Stopwatch()..start();
  final decoded = jsonDecode(raw);
  sw.stop();
  final count = decoded is List ? decoded.length : 0;
  print('[search_index] $label (monolithic v1)');
  print('  entries: $count');
  print('  file size: ${_kb(bytes)} KB');
  print('  json parse: ${sw.elapsedMilliseconds} ms');
}

void _reportShardedSearchIndex(Directory dir, String label) {
  final manifestFile = File('${dir.path}/search_index/manifest.json');
  if (!manifestFile.existsSync()) {
    print('[search_index] $label (sharded v2): missing');
    return;
  }
  final manifestRaw = manifestFile.readAsStringSync();
  final sw = Stopwatch()..start();
  final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
  sw.stop();
  final entryCount = manifest['entryCount'];
  final shards = manifest['shards'];
  final shardList = shards is List ? shards : const [];
  print('[search_index] $label (sharded v2 manifest)');
  print('  entryCount: $entryCount');
  print('  category shards: ${shardList.length}');
  print('  manifest parse: ${sw.elapsedMilliseconds} ms');
  print('  manifest size: ${_kb(manifestRaw.length)} KB');

  var totalBytes = 0;
  for (final shard in shardList) {
    if (shard is! Map) continue;
    final path = shard['path']?.toString();
    if (path == null || path.isEmpty) continue;
    final shardFile = File('${dir.path}/$path');
    if (shardFile.existsSync()) {
      totalBytes += shardFile.lengthSync();
    }
  }
  print('  category files total: ${_kb(totalBytes)} KB');
}

void _reportShards(Directory db, Directory assets) {
  for (final label in ['akasha-db', 'assets/registry']) {
    final dir = label == 'akasha-db' ? db : assets;
    if (!dir.existsSync()) continue;
    var files = 0;
    var bytes = 0;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.contains('${Platform.pathSeparator}shards${Platform.pathSeparator}')) {
        continue;
      }
      if (!entity.path.endsWith('.json')) continue;
      files++;
      bytes += entity.lengthSync();
    }
    print('[shards] $label');
    print('  shard files: $files');
    print('  total size: ${_kb(bytes)} KB (${_mb(bytes)} MB)');
  }
}

int _reportAssetsTotal(Directory assets) {
  if (!assets.existsSync()) return 0;
  var bytes = 0;
  for (final entity in assets.listSync(recursive: true)) {
    if (entity is File) bytes += entity.lengthSync();
  }
  print('[assets/registry] total');
  print('  size: ${_kb(bytes)} KB (${_mb(bytes)} MB)');
  return bytes;
}

String _reportBundleMode(Directory db, Directory assets) {
  final manifestFile = File('${db.path}/manifest.json');
  if (!manifestFile.existsSync()) return 'missing-manifest';
  final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map;
  final shards = manifest['shards'];
  if (shards is! List) return 'invalid-manifest';

  var eagerInManifest = 0;
  for (final s in shards) {
    if (s is Map && s['eager'] == true) eagerInManifest++;
  }

  var bundledShardFiles = 0;
  final shardsRoot = Directory('${assets.path}/shards');
  if (shardsRoot.existsSync()) {
    for (final entity in shardsRoot.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) bundledShardFiles++;
    }
  }

  final mode = bundledShardFiles == shards.length
      ? 'full'
      : bundledShardFiles == eagerInManifest
          ? 'eager-only (ADR-010)'
          : 'partial ($bundledShardFiles bundled)';

  print('[bundle] mode');
  print('  manifest shards: ${shards.length}');
  print('  eager in manifest: $eagerInManifest');
  print('  bundled shard files: $bundledShardFiles');
  print('  mode: $mode');
  if (mode.startsWith('eager-only')) return 'eager-only';
  if (mode == 'full') return 'full';
  return 'partial';
}

int _readEntryCount(Directory db) {
  final file = File('${db.path}/manifest.json');
  if (!file.existsSync()) return 0;
  final json = jsonDecode(file.readAsStringSync()) as Map;
  final count = json['entryCount'];
  return count is int ? count : 0;
}

String _kb(int bytes) => (bytes / 1024).toStringAsFixed(1);

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(2);

Directory _root() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final p = dir.parent;
    if (p.path == dir.path) return Directory.current;
    dir = p;
  }
}
