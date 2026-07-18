// ignore_for_file: avoid_print

import 'dart:io';

import 'registry_bundle_contract.dart';

/// Reports the reviewed release baseline and the independent architecture
/// ceilings for AKASHA's sharded JSON registry.
///
/// Usage: dart run tool/catalog_scale_baseline.dart [--strict]
void main(List<String> args) {
  final strict = args.contains('--strict');
  final root = _projectRoot();
  final source = Directory('${root.path}/akasha-db');
  final output = Directory('${root.path}/assets/registry');
  final sourceRevision = _bundleSourceRevision(output);
  final audit = auditRegistryBundle(
    RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.all,
      sourceRevision: sourceRevision,
    ),
  );

  print('AKASHA Catalog Scale Baseline');
  print('root: ${root.path}');
  print('sourceRevision: $sourceRevision');
  print('schema: v${audit.registrySchemaVersion}');
  print('works: ${audit.entryCount}');
  print(
    'shards: manifest=${audit.manifestShardCount}, '
    'source=${audit.sourceShardFileCount}, eager=${audit.eagerShardCount}, '
    'bundle=${audit.bundledShardCount}',
  );
  print('registry logical size: ${_size(audit.registryLogicalBytes)}');
  print('search index size: ${_size(audit.searchIndexBytes)}');
  print('category index size: ${_size(audit.categoryIndexBytes)}');
  print('manifest size: ${_size(audit.manifestBytes)}');
  print(
    'bundle assets: ${audit.bundleAssetFileCount} files, '
    '${_size(audit.bundleAssetBytes)}',
  );
  print(
    'bundle integrity: missing=${audit.missingBundleShardCount}, '
    'orphan=${audit.orphanBundleShardCount}, '
    'manifestSha=${audit.manifestShaMismatchCount}, '
    'searchSha=${audit.searchShaMismatchCount}, '
    'searchMissingIds=${audit.searchMissingIdCount}, '
    'searchOrphanIds=${audit.searchOrphanIdCount}',
  );
  print('canonical generalCulture: ${audit.canonicalGeneralCultureCount}');
  print('categories:');
  for (final entry in audit.categoryStats.entries) {
    print(
      '  ${entry.key}: works=${entry.value.works}, shards=${entry.value.shards}',
    );
  }

  print('\nScale ceilings (architecture redesign gate):');
  print('  works <= ${CatalogScaleCeilings.entryCount}');
  print('  shards <= ${CatalogScaleCeilings.shardCount}');
  print('  bundle <= ${_size(CatalogScaleCeilings.bundleBytes)}');
  print('  search index <= ${_size(CatalogScaleCeilings.searchIndexBytes)}');

  if (!strict) {
    if (!audit.isValid) {
      stderr.writeln('\nAudit findings:');
      for (final error in audit.errors) {
        stderr.writeln('  - $error');
      }
    }
    return;
  }

  final errors = <String>[...audit.errors];
  _expectExact(
    errors,
    'release works',
    audit.entryCount,
    CatalogReleaseBaseline.entryCount,
  );
  _expectExact(
    errors,
    'release manifest shards',
    audit.manifestShardCount,
    CatalogReleaseBaseline.manifestShardCount,
  );
  _expectExact(
    errors,
    'release source shard files',
    audit.sourceShardFileCount,
    CatalogReleaseBaseline.manifestShardCount,
  );
  _expectExact(
    errors,
    'release eager shards',
    audit.eagerShardCount,
    CatalogReleaseBaseline.eagerShardCount,
  );
  _expectExact(
    errors,
    'release schema',
    audit.registrySchemaVersion,
    CatalogReleaseBaseline.registrySchemaVersion,
  );
  _expectExact(
    errors,
    'canonical generalCulture records',
    audit.canonicalGeneralCultureCount,
    CatalogReleaseBaseline.canonicalGeneralCultureCount,
  );
  _expectExact(
    errors,
    'bundle missing shards',
    audit.missingBundleShardCount,
    CatalogReleaseBaseline.missingShardCount,
  );
  _expectExact(
    errors,
    'bundle orphan shards',
    audit.orphanBundleShardCount,
    CatalogReleaseBaseline.orphanShardCount,
  );
  _expectExact(
    errors,
    'manifest SHA mismatches',
    audit.manifestShaMismatchCount,
    CatalogReleaseBaseline.manifestShaMismatchCount,
  );
  _expectExact(
    errors,
    'packaged full-bundle shards',
    audit.bundledShardCount,
    audit.manifestShardCount,
  );

  _expectAtMost(
    errors,
    'works hard gate',
    audit.entryCount,
    CatalogScaleCeilings.entryCount,
    'redesign search/index loading or move to a remote/data-pack release',
  );
  _expectAtMost(
    errors,
    'shard hard gate',
    audit.manifestShardCount,
    CatalogScaleCeilings.shardCount,
    'revisit the seven-category v4 shard topology',
  );
  _expectAtMost(
    errors,
    'bundle hard gate',
    audit.bundleAssetBytes,
    CatalogScaleCeilings.bundleBytes,
    're-evaluate a remote provider or separate data pack',
  );
  _expectAtMost(
    errors,
    'search-index hard gate',
    audit.searchIndexBytes,
    CatalogScaleCeilings.searchIndexBytes,
    'redesign the search representation before adding more records',
  );

  if (errors.isEmpty) {
    print('\nOK: catalog_scale_baseline --strict');
    return;
  }
  stderr.writeln('\nFAIL: catalog_scale_baseline --strict');
  for (final error in errors) {
    stderr.writeln('  - $error');
  }
  exitCode = 1;
}

void _expectExact(List<String> errors, String label, int actual, int expected) {
  if (actual != expected) {
    errors.add(
      '$label changed: $actual (reviewed release baseline $expected). '
      'Review the source change, then update CatalogReleaseBaseline explicitly.',
    );
  }
}

void _expectAtMost(
  List<String> errors,
  String label,
  int actual,
  int maximum,
  String action,
) {
  if (actual > maximum) {
    errors.add('$label exceeded: $actual > $maximum; $action.');
  }
}

String _bundleSourceRevision(Directory output) {
  final manifest = File('${output.path}/manifest.json');
  if (!manifest.existsSync()) return 'missing';
  final match = RegExp(
    r'"sourceRevision"\s*:\s*"([^"]+)"',
  ).firstMatch(manifest.readAsStringSync());
  return match?.group(1) ?? 'missing';
}

String _size(int bytes) =>
    '$bytes bytes (${(bytes / (1024 * 1024)).toStringAsFixed(2)} MiB)';

Directory _projectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
