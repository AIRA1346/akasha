import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// ADR-010 Option A — G1+ assets bundle must stay eager-only (mirrors --strict).
void main() {
  test('G1+ assets bundle is eager-only and under 15MB (ADR-010)', () {
    final root = _projectRoot();
    final manifestFile = File(p.join(root.path, 'akasha-db', 'manifest.json'));
    final manifest =
        json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final entryCount = manifest['entryCount'] as int;
    final shards = manifest['shards'] as List;

    final eagerCount =
        shards.where((s) => s is Map && s['eager'] == true).length;
    expect(eagerCount, greaterThan(0));
    expect(eagerCount, lessThan(shards.length));

    var bundled = 0;
    var assetsBytes = 0;
    final assetsRoot = Directory(p.join(root.path, 'assets', 'registry'));
    for (final entity in assetsRoot.listSync(recursive: true)) {
      if (entity is! File) continue;
      assetsBytes += entity.lengthSync();
      if (entity.path.contains('${Platform.pathSeparator}shards${Platform.pathSeparator}') &&
          entity.path.endsWith('.json')) {
        bundled++;
      }
    }

    expect(bundled, eagerCount);

    if (entryCount > 2500) {
      expect(
        bundled,
        lessThan(shards.length),
        reason: 'G1+ must not bundle full catalog shards',
      );
    }

    const bundleMaxBytes = 15 * 1024 * 1024;
    expect(
      assetsBytes,
      lessThanOrEqualTo(bundleMaxBytes),
      reason: 'assets/registry must stay under 15MB ADR-010 trigger',
    );
  });
}

Directory _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
