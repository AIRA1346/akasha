import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../tool/registry_source_revision.dart';

void main() {
  test('data-input path contract covers builder inputs only', () {
    expect(
      registrySourceDataPaths,
      <String>[
        'akasha-db/manifest.json',
        'akasha-db/search_index.json',
        'akasha-db/search_index',
        'akasha-db/legacy_aliases.json',
        'akasha-db/franchise_groups.json',
        'akasha-db/shards',
      ],
    );
    expect(
      registrySourceDataPaths.any((path) => path.endsWith('.md')),
      isFalse,
    );
  });

  test('markdown-only commits do not advance data source revision', () {
    final repo = Directory.systemTemp.createTempSync(
      'akasha-registry-source-rev-',
    );
    addTearDown(() {
      if (repo.existsSync()) repo.deleteSync(recursive: true);
    });

    _git(repo, ['init']);
    _git(repo, ['config', 'user.email', 'ci@example.com']);
    _git(repo, ['config', 'user.name', 'CI']);
    _git(repo, ['config', 'commit.gpgsign', 'false']);

    final db = Directory(p.join(repo.path, 'akasha-db'))..createSync();
    File(p.join(db.path, 'manifest.json')).writeAsStringSync('{"v":1}\n');
    File(p.join(db.path, 'search_index.json')).writeAsStringSync('{}\n');
    File(p.join(db.path, 'legacy_aliases.json')).writeAsStringSync('{}\n');
    File(p.join(db.path, 'franchise_groups.json')).writeAsStringSync('{}\n');
    Directory(p.join(db.path, 'search_index')).createSync();
    Directory(p.join(db.path, 'shards', 'manga')).createSync(recursive: true);
    File(
      p.join(db.path, 'shards', 'manga', '00.json'),
    ).writeAsStringSync('[]\n');
    File(p.join(db.path, 'README.md')).writeAsStringSync('# db\n');

    _git(repo, ['add', 'akasha-db']);
    _git(repo, ['commit', '-m', 'data baseline']);
    final dataRevision = resolveRegistrySourceRevision(root: repo);
    expect(dataRevision, isNotEmpty);

    File(p.join(db.path, 'README.md')).writeAsStringSync('# db docs only\n');
    File(p.join(db.path, 'SCHEMA.md')).writeAsStringSync('# schema\n');
    _git(repo, ['add', 'akasha-db/README.md', 'akasha-db/SCHEMA.md']);
    _git(repo, ['commit', '-m', 'docs only']);

    final afterDocs = resolveRegistrySourceRevision(root: repo);
    expect(afterDocs, dataRevision);

    final wholeTree = _git(repo, [
      'log',
      '-1',
      '--format=%H',
      '--',
      'akasha-db',
    ]).trim();
    expect(wholeTree, isNot(dataRevision));

    File(p.join(db.path, 'manifest.json')).writeAsStringSync('{"v":2}\n');
    _git(repo, ['add', 'akasha-db/manifest.json']);
    _git(repo, ['commit', '-m', 'data change']);

    final afterData = resolveRegistrySourceRevision(root: repo);
    final wholeTreeAfterData = _git(repo, [
      'log',
      '-1',
      '--format=%H',
      '--',
      'akasha-db',
    ]).trim();
    expect(afterData, isNot(dataRevision));
    expect(afterData, wholeTreeAfterData);
  });

  test('live repo data revision matches committed bundle provenance', () {
    final root = registryProjectRoot();
    final resolved = resolveRegistrySourceRevision(root: root);
    final manifest = File(p.join(root.path, 'assets/registry/manifest.json'));
    expect(manifest.existsSync(), isTrue);
    final text = manifest.readAsStringSync();
    expect(text, contains('"sourceRevision": "$resolved"'));
  });
}

String _git(Directory root, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed: ${result.stderr}\n${result.stdout}',
    );
  }
  return result.stdout.toString();
}
