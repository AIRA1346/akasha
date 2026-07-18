import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../tool/registry_bundle_contract.dart';

void main() {
  test('reviewed release is a complete full bundle within scale gates', () {
    final root = _projectRoot();
    final output = Directory(p.join(root.path, 'assets', 'registry'));
    final manifest =
        jsonDecode(
              File(p.join(output.path, 'manifest.json')).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final sourceRevision = manifest['sourceRevision']?.toString() ?? '';
    expect(
      sourceRevision,
      isNotEmpty,
      reason: 'bundle manifest must identify the immutable source revision',
    );

    final audit = auditRegistryBundle(
      RegistryBundleSpec(
        source: Directory(p.join(root.path, 'akasha-db')),
        output: output,
        mode: RegistryBundleMode.all,
        sourceRevision: sourceRevision,
      ),
    );
    expect(
      audit.errors,
      isEmpty,
      reason: 'full-bundle contract violations:\n${audit.errors.join('\n')}',
    );
    expect(audit.entryCount, CatalogReleaseBaseline.entryCount);
    expect(audit.manifestShardCount, CatalogReleaseBaseline.manifestShardCount);
    expect(
      audit.sourceShardFileCount,
      CatalogReleaseBaseline.manifestShardCount,
    );
    expect(audit.eagerShardCount, CatalogReleaseBaseline.eagerShardCount);
    expect(
      audit.registrySchemaVersion,
      CatalogReleaseBaseline.registrySchemaVersion,
    );
    expect(
      audit.canonicalGeneralCultureCount,
      CatalogReleaseBaseline.canonicalGeneralCultureCount,
    );
    expect(audit.bundledShardCount, audit.manifestShardCount);
    expect(audit.missingBundleShardCount, 0);
    expect(audit.orphanBundleShardCount, 0);
    expect(audit.manifestShaMismatchCount, 0);
    expect(audit.searchShaMismatchCount, 0);
    expect(audit.searchMissingIdCount, 0);
    expect(audit.searchOrphanIdCount, 0);

    expect(
      audit.entryCount,
      lessThanOrEqualTo(CatalogScaleCeilings.entryCount),
      reason:
          'catalog exceeded the JSON search architecture gate; redesign before release',
    );
    expect(
      audit.manifestShardCount,
      lessThanOrEqualTo(CatalogScaleCeilings.shardCount),
      reason: 'catalog exceeded the seven-category v4 shard topology',
    );
    expect(
      audit.bundleAssetBytes,
      lessThanOrEqualTo(CatalogScaleCeilings.bundleBytes),
      reason:
          'bundle exceeded the local-asset gate; re-evaluate remote/data pack',
    );
    expect(
      audit.searchIndexBytes,
      lessThanOrEqualTo(CatalogScaleCeilings.searchIndexBytes),
      reason: 'master search index exceeded its redesign gate',
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
