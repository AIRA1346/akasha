// ignore_for_file: avoid_print
/// Maintainer — 유저 카탈로그 제안 번들 import·검증
///
/// Usage:
///   dart run tool/apply_catalog_contributions.dart --validate path/to/bundle.json
///   dart run tool/apply_catalog_contributions.dart --import path/to/bundle.json
///
/// import 시 contributions/{add|fix}/pending/{id}.json + status.json 갱신
/// 자동 shard merge는 하지 않습니다.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'catalog_contribution_status_index.dart';
import 'catalog_contribution_validate.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    _usage();
    exit(1);
  }

  final validate = args.contains('--validate');
  final import = args.contains('--import');
  if (!validate && !import) {
    _usage();
    exit(1);
  }

  final pathIdx = args.indexWhere((a) => !a.startsWith('--'));
  if (pathIdx < 0) {
    stderr.writeln('ERROR: bundle JSON path required');
    exit(1);
  }
  final path = args[pathIdx];
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: file not found: $path');
    exit(1);
  }

  final decoded = json.decode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln('ERROR: bundle must be a JSON object');
    exit(1);
  }

  final errors = validateContributionBundle(decoded);
  if (errors.isNotEmpty) {
    stderr.writeln('Validation failed (${errors.length}):');
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }

  final contributions = decoded['contributions'] as List;
  print('OK: ${contributions.length} contribution(s) validated');

  if (!import) exit(0);

  final root = _findProjectRoot();
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));
  final statusIndex = readStatusIndex(root);
  final encoder = const JsonEncoder.withIndent('  ');

  for (final raw in contributions) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) {
      stderr.writeln('WARN: skip entry without id');
      continue;
    }

    final kind = map['kind']?.toString() ?? 'addWork';
    final status = map['status']?.toString() ?? 'submitted';
    final relative = contributionRepoPath(kind: kind, status: status, id: id);
    final target = File(p.join(dbRoot.path, relative));
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(encoder.convert(map));
    upsertStatusEntry(statusIndex, map);
    print('  → $relative');
  }

  writeStatusIndex(root, statusIndex);
  print('Updated → $statusIndexRelativePath');
  print('Next: review, change status, merge shards, registry_builder');
}

void _usage() {
  print('Usage:');
  print('  dart run tool/apply_catalog_contributions.dart --validate <bundle.json>');
  print('  dart run tool/apply_catalog_contributions.dart --import <bundle.json>');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find project root (pubspec.yaml)');
    }
    dir = parent;
  }
}
