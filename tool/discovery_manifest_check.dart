// ignore_for_file: avoid_print
/// pipeline/discovery/manifest.json 스키마 검증
///
/// Usage: dart run tool/discovery_manifest_check.dart

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
    final anilist = manifest.channel('anilist_animation');
    if (anilist == null) {
      stderr.writeln('FAIL: anilist_animation channel missing');
      exit(1);
    }
    if (anilist.source != 'anilist') {
      stderr.writeln('FAIL: anilist_animation source must be anilist');
      exit(1);
    }
    print('OK: discovery manifest v${manifest.version}');
    print('  channels: ${manifest.channels.keys.join(', ')}');
    print('  anilist_animation enabled=${anilist.enabled} limit=${anilist.dailyLimit}');
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
