// ignore_for_file: avoid_print
// Contribution → Quality Loop — 승인된 제안을 샤드에 반영
//
// Usage:
//   dart run tool/merge_catalog_contribution.dart --id <contributionId> [--apply]
//   dart run tool/merge_catalog_contribution.dart --file <contribution.json> [--apply]
//
// 동작:
//   fixWork → 대상 wk_ 샤드에 필드 반영 + qualitySignals 검증 신호 갱신
//   addWork → (수동 권장) 지원 안내만 출력
//   --apply 시 샤드 기록 + status → merged + registry_builder 재실행
//
// score/tier는 저장하지 않는다 (registry_builder가 파생 계산).

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'catalog_contribution_status_index.dart';
import 'quality_loop_utils.dart';
import 'registry_hash_utils.dart';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final id = _argValue(args, '--id');
  final filePath = _argValue(args, '--file');
  final skipBuild = args.contains('--no-build');

  if (id == null && filePath == null) {
    _usage();
    exit(64);
  }

  final root = _findProjectRoot();
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));

  final contribution = _loadContribution(root, dbRoot, id: id, filePath: filePath);
  if (contribution == null) {
    stderr.writeln('ERROR: contribution not found (id=$id file=$filePath)');
    exit(1);
  }

  final kind = contribution['kind']?.toString() ?? '';
  final cid = contribution['id']?.toString() ?? id ?? '(no-id)';

  if (kind == 'addWork') {
    print('addWork merge는 wk_ 발급·중복 검사가 필요해 자동화하지 않습니다.');
    print('수동 절차: 새 wk_ → shards/{category}/{hh}.json → registry_builder');
    exit(0);
  }

  if (kind != 'fixWork') {
    stderr.writeln('ERROR: unsupported kind: $kind');
    exit(1);
  }

  final fix = contribution['fixWork'];
  if (fix is! Map) {
    stderr.writeln('ERROR: fixWork payload missing');
    exit(1);
  }
  final fixMap = Map<String, dynamic>.from(fix);
  final targetWorkId = fixMap['targetWorkId']?.toString() ?? '';
  final fields = fixMap['fields'] is Map
      ? Map<String, dynamic>.from(fixMap['fields'] as Map)
      : <String, dynamic>{};

  if (targetWorkId.isEmpty || fields.isEmpty) {
    stderr.writeln('ERROR: targetWorkId/fields required');
    exit(1);
  }

  final category = _categoryForWorkId(dbRoot, targetWorkId);
  if (category == null) {
    stderr.writeln('ERROR: category not found for $targetWorkId (id_registry)');
    exit(1);
  }

  final hex = shardHexForWorkId(targetWorkId);
  final shardFile = File(p.join(dbRoot.path, v4ShardPath(category, hex)));
  if (!shardFile.existsSync()) {
    stderr.writeln('ERROR: shard not found: ${shardFile.path}');
    exit(1);
  }

  final shard = Map<String, dynamic>.from(
    json.decode(shardFile.readAsStringSync()) as Map,
  );
  if (shard[targetWorkId] is! Map) {
    stderr.writeln('ERROR: $targetWorkId not in ${v4ShardPath(category, hex)}');
    exit(1);
  }

  final work = Map<String, dynamic>.from(shard[targetWorkId] as Map);
  final result = applyFixToWork(work, fields);

  print('fixWork $cid → $targetWorkId (${v4ShardPath(category, hex)})');
  print('  applied fields : ${result.appliedFields.join(', ')}');
  print('  verified signals: ${result.verifiedSignals.isEmpty ? '(none)' : result.verifiedSignals.join(', ')}');
  if (result.skippedFields.isNotEmpty) {
    print('  skipped (not allowed): ${result.skippedFields.join(', ')}');
  }

  if (!apply) {
    print('\nDry-run. Pass --apply to write shard + status + rebuild.');
    return;
  }

  shard[targetWorkId] = result.work;
  final sorted = Map.fromEntries(
    shard.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  shardFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );
  print('  → wrote ${v4ShardPath(category, hex)}');

  _markMerged(root, contribution);
  print('  → status: merged');

  if (skipBuild) {
    print('Skipped registry_builder (--no-build). Run it before push.');
    return;
  }

  print('\n==> registry_builder (source only)');
  final builder = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/registry_builder.dart'],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.write(builder.stdout);
  stderr.write(builder.stderr);
  if (builder.exitCode != 0) {
    stderr.writeln('FAIL: registry_builder exited ${builder.exitCode}');
    exit(builder.exitCode);
  }
  print('OK: qualityScore/Tier recomputed, search_index updated');
}

Map<String, dynamic>? _loadContribution(
  Directory root,
  Directory dbRoot, {
  String? id,
  String? filePath,
}) {
  if (filePath != null) {
    final f = File(filePath);
    if (!f.existsSync()) return null;
    final decoded = json.decode(f.readAsStringSync());
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  // id로 status.json에서 경로 해석
  final statusIndex = readStatusIndex(root);
  final entries = statusIndex['entries'];
  if (entries is Map && entries[id] is Map) {
    final entry = Map<String, dynamic>.from(entries[id] as Map);
    final relative = entry['path']?.toString();
    if (relative != null) {
      final f = File(p.join(dbRoot.path, relative));
      if (f.existsSync()) {
        final decoded = json.decode(f.readAsStringSync());
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      }
    }
  }

  // fallback: contributions/ 폴더 전체 탐색
  final contribDir = Directory(p.join(dbRoot.path, 'contributions'));
  if (!contribDir.existsSync()) return null;
  for (final f in contribDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('$id.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return null;
}

void _markMerged(Directory root, Map<String, dynamic> contribution) {
  final dbRoot = Directory(p.join(root.path, 'akasha-db'));
  final id = contribution['id']?.toString() ?? '';
  final kind = contribution['kind']?.toString() ?? 'fixWork';

  // 옛 경로 파일 제거 (status 변경 → 폴더 이동)
  final statusIndex = readStatusIndex(root);
  final entries = statusIndex['entries'];
  if (entries is Map && entries[id] is Map) {
    final oldRel = (entries[id] as Map)['path']?.toString();
    if (oldRel != null) {
      final oldFile = File(p.join(dbRoot.path, oldRel));
      if (oldFile.existsSync()) oldFile.deleteSync();
    }
  }

  final merged = Map<String, dynamic>.from(contribution);
  merged['status'] = 'merged';
  merged['updatedAt'] = DateTime.now().toUtc().toIso8601String();

  final relative =
      contributionRepoPath(kind: kind, status: 'merged', id: id);
  final target = File(p.join(dbRoot.path, relative));
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(merged)}\n',
  );

  upsertStatusEntry(statusIndex, merged);
  writeStatusIndex(root, statusIndex);
}

String? _categoryForWorkId(Directory dbRoot, String workId) {
  final file = File(p.join(dbRoot.path, 'id_registry.json'));
  if (file.existsSync()) {
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is Map && decoded['byWk'] is Map) {
      final byWk = Map<String, dynamic>.from(decoded['byWk'] as Map);
      final entry = byWk[workId];
      if (entry is Map && entry['category'] != null) {
        return entry['category'].toString();
      }
    }
  }
  // fallback: 샤드 스캔
  final shardsRoot = Directory(p.join(dbRoot.path, 'shards'));
  if (!shardsRoot.existsSync()) return null;
  for (final dir in shardsRoot.listSync().whereType<Directory>()) {
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final decoded = json.decode(f.readAsStringSync());
      if (decoded is Map && decoded.containsKey(workId)) {
        return p.basename(dir.path);
      }
    }
  }
  return null;
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
  final prefix = '$name=';
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}

void _usage() {
  print('Usage:');
  print('  dart run tool/merge_catalog_contribution.dart --id <id> [--apply]');
  print('  dart run tool/merge_catalog_contribution.dart --file <path> [--apply]');
  print('  options: --no-build (skip registry_builder)');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
