import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../tool/registry_bundle_contract.dart';
import '../tool/registry_hash_utils.dart';

void main() {
  late Directory sandbox;
  late Directory source;
  late Directory output;
  const revision = 'source-commit-0123456789abcdef';

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('akasha-bundle-builder-');
    source = Directory(p.join(sandbox.path, 'source'))..createSync();
    output = Directory(p.join(sandbox.path, 'output'));
    _writeSourceFixture(source);
  });

  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  test('full generation is deterministic, immutable, and allowlisted', () {
    final sourceBefore = registryDirectoryDigest(source);
    output.createSync();
    _write(File(p.join(output.path, 'id_registry.json')), '{}\n');
    _write(File(p.join(output.path, 'orphan.json')), '{}\n');

    const builder = RegistryBundleBuilder();
    final spec = RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.all,
      sourceRevision: revision,
    );
    final first = builder.build(spec);
    final firstDigest = registryDirectoryDigest(output);
    final second = builder.build(spec);
    final secondDigest = registryDirectoryDigest(output);

    expect(sourceBefore, registryDirectoryDigest(source));
    expect(first.errors, isEmpty);
    expect(second.errors, isEmpty);
    expect(firstDigest, secondDigest);
    expect(first.bundledShardCount, 1);
    expect(first.bundleAssetFileCount, 7);
    expect(File(p.join(output.path, 'id_registry.json')).existsSync(), isFalse);
    expect(File(p.join(output.path, 'orphan.json')).existsSync(), isFalse);

    final rootManifest = _object(File(p.join(output.path, 'manifest.json')));
    final searchManifest = _object(
      File(p.join(output.path, 'search_index', 'manifest.json')),
    );
    for (final manifest in [rootManifest, searchManifest]) {
      expect(manifest['releaseId'], 'registry-$revision');
      expect(manifest['sourceRevision'], revision);
      expect(manifest['schemaVersion'], 4);
      expect(manifest['bundleMode'], 'full');
      expect(manifest['generatedAt'], '2026-07-18T00:00:00.000Z');
    }
  });

  test('verify-only does not mutate a valid output', () {
    const builder = RegistryBundleBuilder();
    final spec = RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.all,
      sourceRevision: revision,
    );
    builder.build(spec);
    final before = registryDirectoryDigest(output);

    final audit = builder.verify(spec);

    expect(audit.errors, isEmpty);
    expect(registryDirectoryDigest(output), before);
  });

  test('staging validation failure preserves the previous output', () {
    const builder = RegistryBundleBuilder();
    final spec = RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.all,
      sourceRevision: revision,
    );
    builder.build(spec);
    final outputBefore = registryDirectoryDigest(output);

    final manifestFile = File(p.join(source.path, 'manifest.json'));
    final manifest = _object(manifestFile);
    ((manifest['shards'] as List).first as Map)['sha256'] = ''.padLeft(64, '0');
    _writeJson(manifestFile, manifest);

    expect(
      () => builder.build(spec),
      throwsA(isA<RegistryBundleValidationException>()),
    );
    expect(registryDirectoryDigest(output), outputBefore);
    expect(
      sandbox.listSync().whereType<Directory>().where(
        (dir) => p.basename(dir.path).contains('.staging-'),
      ),
      isEmpty,
    );
  });

  test('eager-only is explicit and does not alter the source contract', () {
    const builder = RegistryBundleBuilder();
    final spec = RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.eagerOnly,
      sourceRevision: revision,
    );

    final audit = builder.build(spec);

    expect(audit.bundleMode, 'eager-only');
    expect(audit.bundledShardCount, 1);
    expect(audit.manifestShardCount, 1);
  });

  test('CRLF source JSON produces canonical LF bundle bytes', () {
    for (final file in source.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final value = file.readAsStringSync().replaceAll('\n', '\r\n');
      file.writeAsStringSync(value);
    }
    final spec = RegistryBundleSpec(
      source: source,
      output: output,
      mode: RegistryBundleMode.all,
      sourceRevision: revision,
    );

    const RegistryBundleBuilder().build(spec);

    final shard = output
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere(
          (file) => file.path.contains('${p.separator}shards${p.separator}'),
        );
    expect(shard.readAsStringSync(), isNot(contains('\r\n')));
  });
}

void _writeSourceFixture(Directory source) {
  const workId = 'wk_000000001';
  final shardHex = shardHexForWorkId(workId);
  final shardPath = 'shards/manga/$shardHex.json';
  final shard = {
    workId: {
      'workId': workId,
      'title': 'Fixture',
      'category': 'manga',
      'domain': 'subculture',
    },
  };
  final shardFile = File(p.joinAll([source.path, ...shardPath.split('/')]));
  _writeJson(shardFile, shard);
  final shardSha = sha256HexUtf8(shardFile.readAsStringSync());

  final search = [
    {
      'workId': workId,
      'title': 'Fixture',
      'shardId': 'manga_$shardHex',
      'category': 'manga',
      'domain': 'subculture',
      'creator': '',
      'tags': <String>[],
      'searchTokens': ['fixture'],
    },
  ];
  const generatedAt = '2026-07-18T00:00:00.000Z';
  _writeJson(File(p.join(source.path, 'manifest.json')), {
    'version': 4,
    'shardBits': 8,
    'entryCount': 1,
    'generatedAt': generatedAt,
    'shards': [
      {
        'id': 'manga_$shardHex',
        'category': 'manga',
        'path': shardPath,
        'eager': true,
        'entryCount': 1,
        'sha256': shardSha,
      },
    ],
  });
  _writeJson(File(p.join(source.path, 'search_index.json')), search);
  _writeJson(File(p.join(source.path, 'search_index', 'manga.json')), search);
  _writeJson(File(p.join(source.path, 'search_index', 'manifest.json')), {
    'version': 1,
    'entryCount': 1,
    'generatedAt': generatedAt,
    'shards': [
      {
        'category': 'manga',
        'path': 'search_index/manga.json',
        'entryCount': 1,
        'sha256': sha256HexUtf8(jsonEncode(search)),
      },
    ],
  });
  _writeJson(
    File(p.join(source.path, 'legacy_aliases.json')),
    <String, Object>{},
  );
  _writeJson(
    File(p.join(source.path, 'franchise_groups.json')),
    <String, Object>{},
  );
  _writeJson(File(p.join(source.path, 'id_registry.json')), {
    'sourceOnly': true,
  });
  _writeJson(File(p.join(source.path, 'works_registry.json')), {
    'legacy': true,
  });
}

Map<String, dynamic> _object(File file) =>
    Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);

void _writeJson(File file, Object value) =>
    _write(file, '${const JsonEncoder.withIndent('  ').convert(value)}\n');

void _write(File file, String value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(value);
}
