// ignore_for_file: avoid_print
/// Catalog scale baseline — Phase 2.0 측정 (수정 전 스냅샷).
///
/// Usage: dart run tool/catalog_scale_baseline.dart
///
/// Phase 2 (search/browse/bundle) 착수 **전**·**후** 비교용.
/// 490작에서 수치를 남겨 두면 G1 insert 시 병목 **증명**에 쓴다.

import 'dart:convert';
import 'dart:io';

void main() {
  final root = _root();
  final db = Directory('${root.path}/akasha-db');
  final assets = Directory('${root.path}/assets/registry');

  print('AKASHA Catalog Scale Baseline');
  print('root: ${root.path}\n');

  _reportManifest(db, assets);
  _reportSearchIndex(db, assets);
  _reportShards(db, assets);

  print('\n--- Phase 2 trigger (architecture-evolution-phases) ---');
  print('search_index parse > 50ms @490 → watch');
  print('entryCount > 1000 OR master_index 체감 지연 → Phase 2.1~2.2');
  print('APK assets/registry > 15MB → Phase 2.3');
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
    final file = File('${dir.path}/search_index.json');
    if (!file.existsSync()) {
      print('[search_index] $label: missing');
      continue;
    }
    final bytes = file.lengthSync();
    final raw = file.readAsStringSync();
    final sw = Stopwatch()..start();
    final decoded = jsonDecode(raw);
    sw.stop();
    final count = decoded is List ? decoded.length : 0;
    print('[search_index] $label');
    print('  entries: $count');
    print('  file size: ${_kb(bytes)} KB');
    print('  json parse: ${sw.elapsedMilliseconds} ms');
  }
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
