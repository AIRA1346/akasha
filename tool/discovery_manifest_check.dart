// ignore_for_file: avoid_print
// pipeline/discovery/manifest.json 스키마 검증
//
// Usage: dart run tool/discovery_manifest_check.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'discovery/discovery_manifest.dart';

void main() {
  final root = _findProjectRoot();
  try {
    final manifest = DiscoveryManifest.load(root);
    if (manifest.version < 1) {
      stderr.writeln('FAIL: manifest version < 1');
      exit(1);
    }
    if (manifest.channels.isEmpty) {
      stderr.writeln('FAIL: no channels defined');
      exit(1);
    }

    final anilistChannels = manifest.channels.keys
        .where((id) => id.startsWith('anilist_'))
        .toList();
    if (anilistChannels.isNotEmpty) {
      stderr.writeln(
        'FAIL: AniList discovery channels removed (found: $anilistChannels)',
      );
      exit(1);
    }

    final manga = manifest.channel('wikidata_manga');
    if (manga == null) {
      stderr.writeln('FAIL: wikidata_manga channel missing');
      exit(1);
    }
    if (manga.source != 'wikidata') {
      stderr.writeln('FAIL: wikidata_manga source must be wikidata');
      exit(1);
    }
    if (manga.category != 'manga') {
      stderr.writeln('FAIL: wikidata_manga category must be manga');
      exit(1);
    }
    if (manga.trialBatchSize <= 0 || manga.dailyLimit <= 0) {
      stderr.writeln('FAIL: wikidata_manga limits must be > 0');
      exit(1);
    }

    final raw = File(
      p.join(root.path, 'akasha-db/pipeline/discovery/manifest.json'),
    ).readAsStringSync();
    final decoded = json.decode(raw);
    if (decoded is Map) {
      final principles = decoded['principles'];
      if (principles is Map) {
        if (principles['dataSpine']?.toString() != 'wikidata') {
          stderr.writeln('FAIL: principles.dataSpine must be wikidata');
          exit(1);
        }
        if (principles['qValidationRequired'] != true) {
          stderr.writeln('FAIL: principles.qValidationRequired must be true');
          exit(1);
        }
      }
    }

    final anime = manifest.channel('wikidata_anime');
    if (anime == null) {
      stderr.writeln('FAIL: wikidata_anime channel missing');
      exit(1);
    }
    if (anime.category != 'animation') {
      stderr.writeln('FAIL: wikidata_anime category must be animation');
      exit(1);
    }

    print('OK: discovery manifest v${manifest.version}');
    print('  channels: ${manifest.channels.keys.join(', ')}');
    print(
      '  wikidata_manga enabled=${manga.enabled} limit=${manga.dailyLimit}',
    );
    print(
      '  wikidata_anime enabled=${anime.enabled} (stub)',
    );
    exit(0);
  } catch (e) {
    stderr.writeln('FAIL: $e');
    exit(1);
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
