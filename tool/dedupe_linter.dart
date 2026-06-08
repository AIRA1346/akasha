// ignore_for_file: avoid_print
/// 레지스트리 중복 후보 탐지 — 자동 merge 없음, CI 게이트용
///
/// Usage: dart run tool/dedupe_linter.dart [--report-only]
///
/// 신호 (우선순위):
/// 1. externalIds exact match (hard)
/// 2. legacy slug stem + 동일 category (hard)
/// 3. normalized title + 동일 category + releaseYear ±1 (fuzzy)
///
/// franchise_groups 형제·dedupe_exceptions.json 허용 쌍은 제외.

import 'dart:convert';
import 'dart:io';

import 'dedupe_utils.dart';
import 'wk_id_utils.dart';

void main(List<String> args) {
  final reportOnly = args.contains('--report-only');
  final root = _findProjectRoot();
  final works = _loadWorks(root);
  final franchisePeers = _loadFranchisePeers(root);
  final allowedPairs = _loadAllowedPairs(root);
  final shardIds = works.map((w) => w.workId).toSet();

  var issueCount = 0;
  final issues = <_DedupeIssue>[];

  print('Dedupe linter — ${works.length} works\n');

  // 1. externalIds exact
  final byExternal = <String, List<_WorkRef>>{};
  for (final w in works) {
    w.externalIds.forEach((source, value) {
      final id = value.trim();
      if (id.isEmpty) return;
      final key = '${source.toLowerCase()}:$id';
      byExternal.putIfAbsent(key, () => []).add(w);
    });
  }

  for (final entry in byExternal.entries) {
    final group = entry.value;
    if (group.length < 2) continue;
    for (var i = 0; i < group.length; i++) {
      for (var j = i + 1; j < group.length; j++) {
        final a = group[i];
        final b = group[j];
        if (a.category != b.category) continue;
        if (isPairAllowed(a.workId, b.workId, allowedPairs)) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        issues.add(
          _DedupeIssue(
            signal: 'externalId',
            detail: entry.key,
            works: [a, b],
          ),
        );
      }
    }
  }

  // 2. legacy slug stem + category
  final byLegacySlug = <String, List<_WorkRef>>{};
  for (final w in works) {
    for (final legacy in w.legacyIds) {
      final stem = legacySlugStem(legacy);
      if (stem == null || stem.isEmpty) continue;
      final key = '${w.category}::$stem';
      byLegacySlug.putIfAbsent(key, () => []).add(w);
    }
  }

  for (final entry in byLegacySlug.entries) {
    final group = entry.value;
    if (group.length < 2) continue;
    final distinct = <String, _WorkRef>{};
    for (final w in group) {
      distinct[w.workId] = w;
    }
    final list = distinct.values.toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        if (a.category != b.category) continue;
        if (isPairAllowed(a.workId, b.workId, allowedPairs)) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        issues.add(
          _DedupeIssue(
            signal: 'legacySlug',
            detail: entry.key,
            works: [a, b],
          ),
        );
      }
    }
  }

  // 3. normalized title + category + releaseYear
  final byTitle = <String, List<_WorkRef>>{};
  for (final w in works) {
    for (final norm in w.normalizedTitles) {
      if (norm.length < 2) continue;
      final key = '${w.category}::$norm';
      byTitle.putIfAbsent(key, () => []).add(w);
    }
  }

  for (final entry in byTitle.entries) {
    final group = entry.value;
    if (group.length < 2) continue;
    final distinct = <String, _WorkRef>{};
    for (final w in group) {
      distinct[w.workId] = w;
    }
    final list = distinct.values.toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        if (isPairAllowed(a.workId, b.workId, allowedPairs)) continue;
        if (isFranchiseSibling(a.workId, b.workId, franchisePeers)) continue;
        if (!_releaseYearsCompatible(a.releaseYear, b.releaseYear)) continue;
        issues.add(
          _DedupeIssue(
            signal: 'fuzzyTitle',
            detail: entry.key.split('::').last,
            works: [a, b],
          ),
        );
      }
    }
  }

  // dedupe issue list (same pair + signal may appear once)
  final seen = <String>{};
  final unique = <_DedupeIssue>[];
  for (final issue in issues) {
    final ids = issue.works.map((w) => w.workId).toList()..sort();
    final sig = '${issue.signal}|${ids.join('|')}';
    if (seen.add(sig)) unique.add(issue);
  }

  for (final issue in unique) {
    issueCount++;
    final ids = issue.works.map((w) => w.workId).join(', ');
    final titles = issue.works.map((w) => '"${w.title}"').join(' / ');
    print('─ [${issue.signal}] ${issue.detail}');
    print('  $ids');
    print('  $titles');
    print('');
  }

  if (issueCount == 0) {
    print('No duplicate candidates found.');
  } else {
    print(
      '$issueCount duplicate candidate(s) — review or add to '
      'akasha-db/dedupe_exceptions.json',
    );
  }

  // franchise_groups wk_ 일관성 (Phase C3)
  final franchiseErrors = _validateFranchiseGroups(root, shardIds);
  if (franchiseErrors.isNotEmpty) {
    print('\nFranchise wk_ consistency:');
    for (final e in franchiseErrors) {
      print('  - $e');
    }
    issueCount += franchiseErrors.length;
  } else if (franchisePeers.isNotEmpty) {
    print('\nOK: franchise_groups wk_ members (${franchisePeers.length} works)');
  }

  if (issueCount > 0 && !reportOnly) {
    exit(1);
  }
}

bool _releaseYearsCompatible(int? a, int? b) {
  if (a == null || b == null) return true;
  return (a - b).abs() <= 1;
}

List<String> _validateFranchiseGroups(Directory root, Set<String> shardIds) {
  final errors = <String>[];
  final groupsPath = '${root.path}/akasha-db/franchise_groups.json';
  final file = File(groupsPath);
  if (!file.existsSync()) return errors;

  final raw = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final memberToGroup = <String, String>{};

  raw.forEach((groupId, value) {
    if (groupId.startsWith('_') || value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    final members =
        (map['members'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final primary = map['primaryWorkId']?.toString() ?? '';

    if (members.length < 2) {
      errors.add('$groupId: fewer than 2 members');
    }

    if (primary.isEmpty) {
      errors.add('$groupId: missing primaryWorkId');
    } else if (!isWkId(primary)) {
      errors.add('$groupId: primaryWorkId not wk_: $primary');
    } else if (!members.contains(primary)) {
      errors.add('$groupId: primaryWorkId $primary not in members');
    }

    for (final m in members) {
      if (!isWkId(m)) {
        errors.add('$groupId: member not wk_: $m');
      } else if (!shardIds.contains(m)) {
        errors.add('$groupId: member $m missing from shards');
      }
      final existing = memberToGroup[m];
      if (existing != null && existing != groupId) {
        errors.add('$m: in both $existing and $groupId');
      }
      memberToGroup[m] = groupId;
    }
  });

  return errors;
}

Map<String, Set<String>> _loadFranchisePeers(Directory root) {
  final peers = <String, Set<String>>{};
  final path = '${root.path}/akasha-db/franchise_groups.json';
  if (!File(path).existsSync()) return peers;

  final raw = json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
  raw.forEach((key, value) {
    if (key.startsWith('_') || value is! Map) return;
    final members =
        (value['members'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    for (final m in members) {
      peers.putIfAbsent(m, () => {}).addAll(members.where((x) => x != m));
    }
  });
  return peers;
}

Set<String> _loadAllowedPairs(Directory root) {
  final allowed = <String>{};
  final path = '${root.path}/akasha-db/dedupe_exceptions.json';
  if (!File(path).existsSync()) return allowed;

  final raw = json.decode(File(path).readAsStringSync());
  if (raw is! Map) return allowed;

  final pairs = raw['allowedPairs'];
  if (pairs is! List) return allowed;

  for (final item in pairs) {
    if (item is! Map) continue;
    final a = item['wkA']?.toString() ?? item['a']?.toString();
    final b = item['wkB']?.toString() ?? item['b']?.toString();
    if (a == null || b == null) continue;
    allowed.add(pairKey(a, b));
  }
  return allowed;
}

List<_WorkRef> _loadWorks(Directory root) {
  final works = <_WorkRef>[];
  final shardsRoot = Directory('${root.path}/akasha-db/shards');

  for (final f in shardsRoot.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.json')) continue;
    final decoded = json.decode(f.readAsStringSync());
    if (decoded is! Map) continue;

    for (final entry in decoded.entries) {
      if (entry.value is! Map) continue;
      final work = Map<String, dynamic>.from(entry.value as Map);
      final workId = work['workId']?.toString() ?? entry.key.toString();
      final title = work['title']?.toString() ?? workId;

      final externalIds = <String, String>{};
      final ext = work['externalIds'];
      if (ext is Map) {
        ext.forEach((k, v) {
          final val = v?.toString().trim();
          if (val != null && val.isNotEmpty) {
            externalIds[k.toString()] = val;
          }
        });
      }

      final legacyIds = <String>[];
      final legacy = work['legacyIds'];
      if (legacy is List) {
        for (final id in legacy) {
          final s = id.toString();
          if (s.isNotEmpty) legacyIds.add(s);
        }
      }

      final normalizedTitles = <String>{};
      void addTitle(String? t) {
        if (t == null || t.isEmpty) return;
        final n = normalizeTitle(t);
        if (n.isNotEmpty) normalizedTitles.add(n);
      }

      addTitle(title);
      final titles = work['titles'];
      if (titles is Map) {
        titles.forEach((_, v) => addTitle(v?.toString()));
      }
      final aliases = work['aliases'];
      if (aliases is List) {
        for (final a in aliases) {
          addTitle(a?.toString());
        }
      }

      works.add(
        _WorkRef(
          workId: workId,
          title: title,
          category: work['category']?.toString() ?? 'unknown',
          releaseYear: work['releaseYear'] is int
              ? work['releaseYear'] as int
              : int.tryParse(work['releaseYear']?.toString() ?? ''),
          externalIds: externalIds,
          legacyIds: legacyIds,
          normalizedTitles: normalizedTitles,
        ),
      );
    }
  }
  return works;
}

class _WorkRef {
  _WorkRef({
    required this.workId,
    required this.title,
    required this.category,
    required this.releaseYear,
    required this.externalIds,
    required this.legacyIds,
    required this.normalizedTitles,
  });

  final String workId;
  final String title;
  final String category;
  final int? releaseYear;
  final Map<String, String> externalIds;
  final List<String> legacyIds;
  final Set<String> normalizedTitles;
}

class _DedupeIssue {
  _DedupeIssue({
    required this.signal,
    required this.detail,
    required this.works,
  });

  final String signal;
  final String detail;
  final List<_WorkRef> works;
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current;
    dir = parent;
  }
}
