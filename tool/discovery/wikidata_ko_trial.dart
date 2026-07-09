// ignore_for_file: avoid_print
// 한국어(ko) 라벨 Wikidata 작품 — Discovery trial (dry-run / apply).
//
// Usage:
//   dart run tool/discovery/wikidata_ko_trial.dart --category manga --limit 10
//   dart run tool/discovery/wikidata_ko_trial.dart --category manga --limit 15 --offset 500 --apply --build
//   dart run tool/discovery/wikidata_ko_trial.dart --category all --limit 3
//
// Categories: manga, webtoon, animation, game, book, movie, drama, all

import 'dart:io';

import 'package:path/path.dart' as p;

import 'wikidata_ko_fetch.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final build = args.contains('--build');
  final categoryArg = _argValue(args, '--category') ?? 'manga';
  final limit = int.tryParse(_argValue(args, '--limit') ?? '') ?? 20;
  final offset = int.tryParse(_argValue(args, '--offset') ?? '');

  if (limit <= 0) {
    stderr.writeln('ERROR: --limit must be > 0');
    exit(64);
  }

  final categories = categoryArg == 'all'
      ? List<String>.from(wikidataKoSupportedCategories)
      : [categoryArg];

  for (final cat in categories) {
    if (!wikidataKoSupportedCategories.contains(cat)) {
      stderr.writeln(
        'ERROR: unknown category $cat '
        '(use: ${wikidataKoSupportedCategories.join(", ")}, all)',
      );
      exit(64);
    }
  }

  final root = _findProjectRoot();
  final dart = Platform.resolvedExecutable;

  print('wikidata_ko_trial — categories=${categories.join(", ")} limit=$limit');
  if (offset != null) print('  offset: $offset');
  print('  apply: $apply  build: $build');
  print('');

  var hadFailure = false;

  for (final cat in categories) {
    final channelId = 'wikidata_ko_$cat';
    print('========== $channelId ==========');

    final trialArgs = [
      'run',
      'tool/discovery/trial_apply.dart',
      '--live',
      '--channel',
      channelId,
      '--batch-size',
      '$limit',
      '--max-create',
      '$limit',
    ];
    if (apply) trialArgs.add('--apply');
    if (offset != null) {
      trialArgs.addAll(['--offset', '$offset']);
    }

    final result = await Process.run(
      dart,
      trialArgs,
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      hadFailure = true;
      print('FAIL: $channelId exited ${result.exitCode}');
    }
    print('');
  }

  if (apply && build && !hadFailure) {
    print('==> registry_builder --sync-assets --bundle-eager-only');
    final buildResult = await Process.run(
      dart,
      [
        'run',
        'tool/registry_builder.dart',
        '--sync-assets',
        '--bundle-eager-only',
      ],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(buildResult.stdout);
    stderr.write(buildResult.stderr);
    if (buildResult.exitCode != 0) exit(buildResult.exitCode);
  }

  exit(hadFailure ? 1 : 0);
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  return null;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
