import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets bundle is eager-only at G1 scale (ADR-010)', () {
    final manifestFile = File('akasha-db/manifest.json');
    expect(manifestFile.existsSync(), isTrue);

    final manifest =
        json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final entryCount = manifest['entryCount'] as int;
    final shards = manifest['shards'] as List;
    final eagerPaths = <String>{
      for (final s in shards)
        if (s is Map && s['eager'] == true) s['path'] as String,
    };

    expect(entryCount, greaterThanOrEqualTo(5000));
    expect(eagerPaths.length, greaterThan(0));
    expect(eagerPaths.length, lessThan(shards.length));

    var bundledShardFiles = 0;
    final assetsShards = Directory('assets/registry/shards');
    if (assetsShards.existsSync()) {
      for (final entity in assetsShards.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          bundledShardFiles++;
        }
      }
    }

    expect(
      bundledShardFiles,
      eagerPaths.length,
      reason: 'assets should bundle eager shards only (ADR-010)',
    );
  });
}
