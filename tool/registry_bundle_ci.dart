// ignore_for_file: avoid_print

import 'dart:io';

import 'registry_bundle_contract.dart';

void main() {
  final root = _projectRoot();
  final source = Directory('${root.path}/akasha-db');
  final assets = Directory('${root.path}/assets/registry');
  final sourceRevision = _git(root, [
    'log',
    '-1',
    '--format=%H',
    '--',
    'akasha-db',
  ]).trim();
  if (sourceRevision.isEmpty) {
    stderr.writeln('FAIL: could not resolve the akasha-db source revision');
    exitCode = 1;
    return;
  }
  final sourceStatusBefore = _git(root, [
    'status',
    '--porcelain=v1',
    '--untracked-files=all',
    '--',
    'akasha-db',
  ]);
  final sandbox = Directory.systemTemp.createTempSync('akasha-registry-ci-');
  final firstOutput = Directory('${sandbox.path}/first');
  final secondOutput = Directory('${sandbox.path}/second');
  final builder = const RegistryBundleBuilder();

  try {
    print('==> verify committed full bundle');
    final committed = builder.verify(
      RegistryBundleSpec(
        source: source,
        output: assets,
        mode: RegistryBundleMode.all,
        sourceRevision: sourceRevision,
      ),
    );
    print(
      'OK: ${committed.entryCount} works, '
      '${committed.bundledShardCount} shards, '
      '${committed.bundleAssetFileCount} files',
    );

    print('==> generate two isolated full bundles');
    for (final output in [firstOutput, secondOutput]) {
      builder.build(
        RegistryBundleSpec(
          source: source,
          output: output,
          mode: RegistryBundleMode.all,
          sourceRevision: sourceRevision,
        ),
      );
    }
    final firstDigest = registryDirectoryDigest(firstOutput);
    final secondDigest = registryDirectoryDigest(secondOutput);
    if (firstDigest != secondDigest) {
      throw RegistryBundleValidationException([
        'deterministic output mismatch: $firstDigest != $secondDigest',
      ]);
    }
    print('OK: deterministic output $firstDigest');

    final sourceStatusAfter = _git(root, [
      'status',
      '--porcelain=v1',
      '--untracked-files=all',
      '--',
      'akasha-db',
    ]);
    if (sourceStatusAfter != sourceStatusBefore) {
      throw RegistryBundleValidationException([
        'akasha-db working tree changed during bundle generation',
        'before: ${sourceStatusBefore.trim()}',
        'after: ${sourceStatusAfter.trim()}',
      ]);
    }
    print('OK: source working tree unchanged');
  } on RegistryBundleValidationException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  }
}

String _git(Directory root, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout.toString();
}

Directory _projectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
