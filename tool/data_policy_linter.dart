// ignore_for_file: avoid_print
/// Registry Data Policy CI — [docs/data-policy.md](../docs/data-policy.md)
///
/// Usage: dart run tool/data_policy_linter.dart [--contributions] [--strict]
///   --strict : warnOnly 위반도 CI 실패로 승격 (레거시 정리 완료 후)
///
/// 검사:
/// - 금지 필드 (synopsis, overview, review, tagline, …)
/// - raw API blob 시그니처
/// - poster URL (denylist, self-hosted, http only)
/// - 텍스트 길이 상한 (description, title, tags, …)
/// - provenance (posterSource, registeredVia, qualitySignals)
///
/// Exit 0 = OK, 1 = violations

import 'dart:convert';
import 'dart:io';

import 'data_policy_utils.dart';

void main(List<String> args) {
  final scanContributions = args.contains('--contributions');
  final strict = args.contains('--strict');
  final root = _findProjectRoot();
  final issues = <DataPolicyViolation>[];

  issues.addAll(_scanShards(Directory('${root.path}/akasha-db/shards'), 'shards'));

  final searchIndex = File('${root.path}/akasha-db/search_index.json');
  if (searchIndex.existsSync()) {
    issues.addAll(_scanSearchIndex(searchIndex));
  }

  if (scanContributions) {
    issues.addAll(
      _scanContributions(Directory('${root.path}/akasha-db/contributions')),
    );
  }

  final errors =
      issues.where((i) => strict || !i.warnOnly).toList();
  final warnings =
      strict ? <DataPolicyViolation>[] : issues.where((i) => i.warnOnly).toList();

  print(
    'Data Policy linter${strict ? ' [strict]' : ''} — '
    '${errors.length} error(s), ${warnings.length} warning(s)\n',
  );

  if (errors.isEmpty && warnings.isEmpty) {
    print('OK: all registry entries comply with data-policy.md');
    exit(0);
  }

  if (errors.isNotEmpty) {
    print('Errors:');
    for (final issue in errors) {
      print('  - $issue');
    }
    print('');
  }

  if (warnings.isNotEmpty) {
    print('Warnings (non-blocking):');
    final show = warnings.length > 15 ? warnings.take(15) : warnings;
    for (final issue in show) {
      print('  - $issue');
    }
    if (warnings.length > 15) {
      print('  ... and ${warnings.length - 15} more warnings');
    }
    print('');
  }

  final byRule = <String, int>{};
  for (final issue in errors) {
    byRule[issue.rule] = (byRule[issue.rule] ?? 0) + 1;
  }
  if (byRule.isNotEmpty) {
    print('Errors by rule:');
    for (final entry in byRule.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    print('');
  }

  if (errors.isNotEmpty) {
    print('See docs/data-policy.md');
    exit(1);
  }

  print('OK: no blocking violations (warnings only)');
  exit(0);
}

List<DataPolicyViolation> _scanShards(Directory shardsRoot, String prefix) {
  final issues = <DataPolicyViolation>[];
  if (!shardsRoot.existsSync()) return issues;

  for (final file in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final relative = _relativeAkashaPath(file.path, prefix);

    Map<String, dynamic> shard;
    try {
      final decoded = json.decode(file.readAsStringSync());
      if (decoded is! Map) continue;
      shard = Map<String, dynamic>.from(decoded);
    } catch (e) {
      issues.add(
        DataPolicyViolation(
          workId: '-',
          relativePath: relative,
          rule: 'json',
          detail: 'invalid JSON: $e',
        ),
      );
      continue;
    }

    for (final entry in shard.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      issues.addAll(
        lintWorkEntry(workId: workId, work: work, relativePath: relative),
      );
    }
  }

  return issues;
}

List<DataPolicyViolation> _scanSearchIndex(File file) {
  final issues = <DataPolicyViolation>[];
  try {
    final decoded = json.decode(file.readAsStringSync());
    if (decoded is! List) return issues;

    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final workId = map['workId']?.toString() ?? '';

      for (final forbidden in ['description', 'synopsis', 'overview']) {
        if (map.containsKey(forbidden)) {
          issues.add(
            DataPolicyViolation(
              workId: workId,
              relativePath: 'search_index.json',
              rule: 'forbidden_field',
              detail: 'search_index must not contain "$forbidden"',
            ),
          );
        }
      }

      final poster = map['posterPath']?.toString() ?? '';
      if (poster.isNotEmpty) {
        issues.add(
          DataPolicyViolation(
            workId: workId,
            relativePath: 'search_index.json',
            rule: 'tier1_poster',
            detail: 'search_index must not contain posterPath (v1)',
          ),
        );
      }
    }
  } catch (e) {
    issues.add(
      DataPolicyViolation(
        workId: '-',
        relativePath: 'search_index.json',
        rule: 'json',
        detail: 'invalid JSON: $e',
      ),
    );
  }
  return issues;
}

List<DataPolicyViolation> _scanContributions(Directory root) {
  final issues = <DataPolicyViolation>[];
  if (!root.existsSync()) return issues;

  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    if (file.path.endsWith('status.json')) continue;

    final relative = _relativeAkashaPath(file.path, 'contributions');
    try {
      final decoded = json.decode(file.readAsStringSync());
      if (decoded is! Map) continue;
      final map = Map<String, dynamic>.from(decoded);

      final addWork = map['addWork'];
      if (addWork is Map) {
        final proposal = Map<String, dynamic>.from(addWork);
        final pseudo = <String, dynamic>{
          'workId': map['id']?.toString() ?? 'proposal',
          'title': proposal['title'],
          'titles': proposal['titles'],
          'category': proposal['category'],
          'domain': proposal['domain'],
          'creator': proposal['creator'],
          'releaseYear': proposal['releaseYear'],
          'description': proposal['description'],
          'tags': proposal['tags'],
          'posterPath': proposal['posterPath'],
          'externalIds': proposal['externalIds'],
        };
        issues.addAll(
          lintWorkEntry(
            workId: pseudo['workId'].toString(),
            work: pseudo,
            relativePath: relative,
          ),
        );
      }

      final fixWork = map['fixWork'];
      if (fixWork is Map) {
        final fields = fixWork['fields'];
        if (fields is Map) {
          for (final entry in fields.entries) {
            final key = entry.key.toString();
            if (forbiddenFieldKeys.contains(key)) {
              issues.add(
                DataPolicyViolation(
                  workId: map['id']?.toString() ?? 'fix',
                  relativePath: relative,
                  rule: 'forbidden_field',
                  detail: 'fixWork.fields contains "$key"',
                ),
              );
            }
            if (key == 'description') {
              final text = entry.value?.toString() ?? '';
              if (text.length > dataPolicyMaxDescriptionChars) {
                issues.add(
                  DataPolicyViolation(
                    workId: map['id']?.toString() ?? 'fix',
                    relativePath: relative,
                    rule: 'text_length',
                    detail: 'fixWork description too long (${text.length})',
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      issues.add(
        DataPolicyViolation(
          workId: '-',
          relativePath: relative,
          rule: 'json',
          detail: 'invalid JSON: $e',
        ),
      );
    }
  }

  return issues;
}

String _relativeAkashaPath(String fullPath, String prefix) {
  final normalized = fullPath.replaceAll('\\', '/');
  final marker = '/akasha-db/';
  final idx = normalized.indexOf(marker);
  if (idx >= 0) {
    return normalized.substring(idx + marker.length);
  }
  return '$prefix/${normalized.split('/').last}';
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  throw StateError('pubspec.yaml not found');
}
