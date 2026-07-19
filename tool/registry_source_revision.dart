// ignore_for_file: avoid_print

import 'dart:io';

/// Paths that the registry full-bundle builder actually consumes from
/// `akasha-db/`. Markdown and other non-input files are intentionally
/// excluded so provenance does not advance on docs-only commits.
const List<String> registrySourceDataPaths = <String>[
  'akasha-db/manifest.json',
  'akasha-db/search_index.json',
  'akasha-db/search_index',
  'akasha-db/legacy_aliases.json',
  'akasha-db/franchise_groups.json',
  'akasha-db/shards',
];

typedef RegistryGitRunner =
    String Function(Directory root, List<String> args);

/// Resolves the committed revision of registry **data inputs** only.
String resolveRegistrySourceRevision({
  Directory? root,
  RegistryGitRunner? git,
}) {
  final projectRoot = root ?? registryProjectRoot();
  final runner = git ?? _defaultGit;
  final revision = runner(projectRoot, <String>[
    'log',
    '-1',
    '--format=%H',
    '--',
    ...registrySourceDataPaths,
  ]).trim();
  if (revision.isEmpty) {
    throw StateError(
      'could not resolve registry source revision for data inputs: '
      '${registrySourceDataPaths.join(', ')}',
    );
  }
  return revision;
}

Directory registryProjectRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return start ?? Directory.current;
    dir = parent;
  }
}

String _defaultGit(Directory root, List<String> args) {
  final result = Process.runSync('git', args, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout.toString();
}

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Print the git revision of akasha-db registry data inputs.\n'
      'Usage: dart run tool/registry_source_revision.dart [--print-paths]',
    );
    return;
  }
  if (args.contains('--print-paths')) {
    for (final path in registrySourceDataPaths) {
      stdout.writeln(path);
    }
    return;
  }
  try {
    stdout.writeln(resolveRegistrySourceRevision());
  } catch (error) {
    stderr.writeln('FAIL: $error');
    exitCode = 1;
  }
}
